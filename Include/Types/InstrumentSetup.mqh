class INSTRUMENT_SETUP {
   public:
   string name;
   double opm; // Opening Position Movement
   double tpm; // Take Profit Movement
   double slm; // Stop Loss Movement   
   double tp_listener;
   
   INSTRUMENT_SETUP() {
      this.name = "NQ100";
      this.opm = 10;
      this.tpm = 0.1;
      this.slm = 1;
      this.tp_listener = 10;   
   }
};