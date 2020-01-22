class BP {
    public:
    double handler;
    double buffer[];

    BP() {
        this.reset();
    }

    void reset() {
        this.handler = 0;
        ArrayFree( this.buffer );
    }

    int calculate(
        ENUM_TIMEFRAMES trade_period, 
        int bars
    ) {
        double direction = 0; // -1 = SELL; 0 = Neutral; 1 = BUY;
        int scales = 0;

        this.handler = iBullsPower( Symbol(), trade_period, bars );
        CopyBuffer( this.handler, 0, 0, bars, this.buffer );
        
        double current_bp = NormalizeDouble( this.buffer[ bars - 1 ], 3 );

        for ( int count_bars = bars - 1; count_bars >= 1; count_bars-- ) {
            this.buffer[ count_bars ] = NormalizeDouble( this.buffer[ count_bars ], 2 );
            this.buffer[ count_bars - 1 ] = NormalizeDouble( this.buffer[ count_bars - 1 ], 2 );

            if ( this.buffer[ count_bars ] > this.buffer[ count_bars - 1 ] ) {
                scales += 1;
            } else if ( this.buffer[ count_bars ] < this.buffer[ count_bars - 1 ] ) {
                scales -= 1;
            }
        }

        if ( 
            scales > 0 &&
            current_bp > 1
        ) { 
            direction = 1; 
        } else if ( 
            scales < 0 &&
            current_bp < -1
        ) { 
            direction = -1; 
        }

        return direction;
    }
}