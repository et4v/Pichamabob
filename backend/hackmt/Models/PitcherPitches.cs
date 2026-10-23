namespace HackMT2026.Models
{
    public class PitcherPitches
    {
        public int PlayerId { get; set; }
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public int PlayerNumber { get; set; }
        public string TeamName { get; set; }
        public string Season { get; set; }
        public string AgeGroup { get; set; }
        public List<Pitch> PitchData { get; set; } = new List<Pitch>();
    }
}