namespace HackMT2026.Models
{
    public class Pitch
    {
        public int PitchNumber { get; set; }
        public int PitcherId { get; set; }
        public int GameId { get; set; }
        public string PitchType { get; set; }
        public int CoachCall { get; set; }
        public int ActualCall { get; set; }
        public string Outcome { get; set; }
        public int BatterId { get; set; }
    }
}