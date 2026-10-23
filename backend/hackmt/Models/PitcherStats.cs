namespace HackMT2026.Models
{
    public class PitcherStats
    {
        public int PlayerId { get; set; }
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public int PlayerNumber { get; set; }
        public string TeamName { get; set; }
        public string Season { get; set; }
        public string AgeGroup { get; set; }
        public int TotalAccurate { get; set; }
        public int TotalPitches { get; set; }

        // Key = Pitch Type (e.g. "Fastball", "Curveball")
        public Dictionary<string, PitchTypeStats> PitchTypes { get; set; }
            = new Dictionary<string, PitchTypeStats>();
    }
}