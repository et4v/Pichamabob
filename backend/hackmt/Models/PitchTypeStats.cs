namespace HackMT2026.Models
{
    public class PitchTypeStats
    {
        public int Strikes { get; set; }
        public int Balls { get; set; }
        public int Fouls { get; set; }
        public int InPlay { get; set; }

        public int Total =>
            Strikes + Balls + Fouls + InPlay;
    }
}