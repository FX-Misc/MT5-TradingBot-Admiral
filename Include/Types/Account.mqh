class ACCOUNT {
   public:
   string currency;
   string broker;
   double currency_exchange_rate;
   double trading_percent;
   double initial_deposit;
   double margin_call;
   int leverage;
   int ping_interval;

   ACCOUNT() {
      // Get Account Currency
      this.currency = AccountInfoString( ACCOUNT_CURRENCY );

      // Set Broker Name
      this.broker = "AdmiralMarkets";

      // Set Currency Exchange Rate to USD (Because NQ100 is USD :O)      
      this.set_currency_exchange_rate();

      // Set Trading Percent (How much of your account are you willing to play with)
      this.trading_percent = 50.0 / 100.0;

      // Set the Initial Deposit on BOT start
      this.initial_deposit = AccountInfoDouble( ACCOUNT_FREEMARGIN );

      // Set account levarage
      this.leverage = AccountInfoInteger( ACCOUNT_LEVERAGE ) > 20 ? 20 : AccountInfoInteger( ACCOUNT_LEVERAGE );

      // Set minimum possible Margin Call
      this.margin_call = 150.0;

      // Set Ping Interval in Seconds
      this.ping_interval = 10;
   }

   void set_currency_exchange_rate() {
      if ( this.currency == "EUR" ) {
         this.currency_exchange_rate = NormalizeDouble( SymbolInfoDouble( "EURUSD", SYMBOL_BID ), 2 );
      } else if ( this.currency == "BGN" ) {
         this.currency_exchange_rate = NormalizeDouble( 1.000 / SymbolInfoDouble( "USDBGN", SYMBOL_BID ), 2 );
      } else if ( this.currency == "USD" ) {
         this.currency_exchange_rate = 1.000;
      }
   }

   void open_position_notification( string type, double price, double volume ) {
      // Info Data
      double balance = AccountInfoDouble( ACCOUNT_BALANCE );
      string position_info = position_.is_opened ? "&account_balance="+ balance +"&serial="+ position_.serialize() : "";

      string cookie = NULL, headers;
      char post[], result[];
      string api_key = IntegerToString( AccountInfoInteger( ACCOUNT_LOGIN ) );
      string data = "action=mt5_opn&api_key="+ api_key +"&type="+ type +"&price="+ price +"&volume="+ volume + position_info;
      StringToCharArray( data, post );
      string url = "https://geronikolov.com/wp-admin/admin-ajax.php";

      ResetLastError();

      int res = WebRequest( "POST", url, cookie, NULL, 500, post, ArraySize( post ), result, headers );

      if ( res != 200 ) { 
         Print( "Error in WebRequest. Error code: ", GetLastError() );

         // Retry the call
         this.open_position_notification( type, price, volume );
      }
   }

   void closed_position_notification( bool is_sl ) {
      // Info Data
      double balance = AccountInfoDouble( ACCOUNT_BALANCE );
      string position_info = position_.is_opened ? "&position_profit="+ position_.profit +"&account_balance="+ balance : "";

      // Request Structure
      string cookie = NULL, headers;
      char post[], result[];
      string api_key = IntegerToString( AccountInfoInteger( ACCOUNT_LOGIN ) );
      string data = "action=mt5_cpn&api_key="+ api_key +"&is_sl="+ is_sl + position_info;
      StringToCharArray( data, post );
      string url = "https://geronikolov.com/wp-admin/admin-ajax.php";

      ResetLastError();

      int res = WebRequest( "POST", url, cookie, NULL, 500, post, ArraySize( post ), result, headers );

      if ( res != 200 ) { 
         Print( "Error in WebRequest. Error code: ", GetLastError() );
         
         // Retry the call
         this.closed_position_notification( is_sl );
      }
   }

   void ping() {
      // Info Data
      double balance = AccountInfoDouble( ACCOUNT_BALANCE );
      string position_info = position_.is_opened ? "&position_profit="+ position_.profit : "";
      string api_key = IntegerToString( AccountInfoInteger( ACCOUNT_LOGIN ) );

      // Request Structure
      string cookie = NULL, headers;
      char post[], result[];      
      string data = "action=mt5_ping&api_key="+ api_key +"&broker="+ this.broker +"&balance="+ balance + position_info;
      StringToCharArray( data, post );
      string url = "https://geronikolov.com/wp-admin/admin-ajax.php";

      ResetLastError();

      int res = WebRequest( "POST", url, cookie, NULL, 500, post, ArraySize( post ), result, headers );

      if ( res != 200 ) { 
         Print( "Error in WebRequest. Error code: ", GetLastError() ); 

         // Retry the call
         this.ping();   
      }
   }

   void recover() {
      string api_key = IntegerToString( AccountInfoInteger( ACCOUNT_LOGIN ) );

      // Request Structure
      string cookie = NULL, headers;
      char post[], result[];      
      string data = "action=mt5_gcp&api_key="+ api_key;
      StringToCharArray( data, post );
      string url = "https://geronikolov.com/wp-admin/admin-ajax.php";

      ResetLastError();

      int res = WebRequest( "POST", url, cookie, NULL, 500, post, ArraySize( post ), result, headers );
      string position_serial = CharArrayToString( result );

      if ( res != 200 ) { 
         Print( "Error in WebRequest. Error code: ", GetLastError() ); 

         // Retry the call
         this.recover();   
      } else if ( res == 200 ) {
         if ( 
            position_serial != "Failed" &&
            position_serial != "None"
         ) {
            position_.deserialize( position_serial );
            Print( "Previously opened position was recovered!" );
         } else if ( position_serial == "Failed" ) {
            Print( "Position reading failed! Wrong API_KEY or missing position." );
         }
      }
   }

   void get_current_position_closing_action() {
      string api_key = IntegerToString( AccountInfoInteger( ACCOUNT_LOGIN ) );

      // Request Structure
      string cookie = NULL, headers;
      char post[], result[];      
      string data = "action=mt5_gcpca&api_key="+ api_key;
      StringToCharArray( data, post );
      string url = "https://geronikolov.com/wp-admin/admin-ajax.php";

      ResetLastError();

      int res = WebRequest( "POST", url, cookie, NULL, 500, post, ArraySize( post ), result, headers );
      string response = CharArrayToString( result );

      if ( res != 200 ) { 
         Print( "Error in WebRequest. Error code: ", GetLastError() );

         // Retry the Call
         this.get_current_position_closing_action();
      } else if ( res == 200 ) {
         if ( response != "Failed" ) {
            if ( response == "true" ) {
               // Get Current Position Data
               position_.select = PositionSelect( Symbol() );
               position_.profit = PositionGetDouble( POSITION_PROFIT );

               // Close the Position
               close_position( position_.type, position_.profit > 0 ? false : true );
            }
         } else {
            Print( "Current Position Actions Reading Failed" );
         }
      }
   }
};