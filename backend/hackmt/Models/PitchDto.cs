namespace HackMT2026.Models
{
    public class PitchDto
    {
        // Pitch info
        public int PitchNumber { get; set; }
        public int GameID { get; set; }
        public string PitchType { get; set; } = string.Empty;
        public int CoachCall { get; set; }
        public int ActualCall { get; set; }
        public string Outcome { get; set; } = string.Empty;

        // Pitcher info
        public int PitcherID { get; set; }
        public string PitcherFirstName { get; set; } = string.Empty;
        public string PitcherLastName { get; set; } = string.Empty;
        public int PitcherNumber { get; set; }

        // Batter info
        public int BatterID { get; set; }
        public string BatterFirstName { get; set; } = string.Empty;
        public string BatterLastName { get; set; } = string.Empty;
        public int BatterNumber { get; set; }
    }
}
