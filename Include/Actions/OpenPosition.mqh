void open_position( string type, double price ) {
    // Reset the Currency Exchange Rate
    account_.set_currency_exchange_rate();

    // Calculate Position Setup
    double free_margin = AccountInfoDouble( ACCOUNT_FREEMARGIN ) * account_.currency_exchange_rate;
    int account_leverage = AccountInfoInteger( ACCOUNT_LEVERAGE );
    double volume = NormalizeDouble( ( free_margin * account_.trading_percent ) * account_leverage / price, 1 );

    // Check if volume is above 500 and set the maximum for the Admiral Markets broker = 500
    if ( volume > 500 ) { volume = 500; }

    // Calculate Stop Loss price
    double stop_loss = 0;
    double stop_loss_difference = instrument_.slm * price;
    if ( type == "sell" ) { stop_loss = price + stop_loss_difference; }
    else if ( type == "buy" ) { stop_loss = price - stop_loss_difference; }

    // Calculate Take Profit price
    double take_profit = 0;
    double take_profit_difference = instrument_.tpm * price;
    if ( type == "sell" ) { take_profit = price - take_profit_difference; }
    else if ( type == "buy" ) { take_profit = price + take_profit_difference; }

    // Order Setup
    order_request.action = TRADE_ACTION_DEAL; 
    order_request.magic = position_.id;
    order_request.order = NULL;
    order_request.type = type == "buy" ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
    order_request.symbol = Symbol();
    order_request.volume = volume;
    order_request.price = price;
    order_request.stoplimit = NULL;
    order_request.sl = NULL;
    order_request.tp = NULL;
    order_request.deviation = NULL;

    // Execute the Order
    bool is_opened_order = OrderSend( order_request, order_result );

    // If everything went smoothly proceed with Position Data setup
    if ( is_opened_order ) {
        ZeroMemory( order_request );
        ZeroMemory( order_result );

        position_.type = type;
        position_.opening_price = price;
        position_.volume = volume; 
        position_.is_opened = true;
        position_.rsi = trend_.rsi;
        position_.bulls_power = trend_.bulls_power;
        position_.lowest_price = position_.opening_price;
        position_.highest_price = position_.opening_price;
        position_.set_tpl();

        // Send Open Position Notification
        account_.open_position_notification( position_.type, position_.opening_price, position_.volume );
    }
}