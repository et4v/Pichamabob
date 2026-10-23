namespace HackMT2026.Models
{
    public class Pitcher
    {
        public int PlayerId { get; set; }
        public string FName { get; set; } = string.Empty;
        public string LName { get; set; } = string.Empty;
        public int PlayerNumber { get; set; }
        public string TeamName { get; set; } = string.Empty;
        public int Season { get; set; }
        public string AgeGroup { get; set; } = string.Empty;
    }
}
