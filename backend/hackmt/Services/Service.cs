using HackMT2026.Models;

public class Service
{
    private Database _database;
    public Service(Database database)
    {
        _database = database;
    }

    public List<PitchDto> GetAllPitches()
    {
        return _database.GetAllPitches();
    }

    public List<Pitcher> GetAllPitchers()
    {
        return _database.GetAllPitchers();
    }

    public Pitcher GetPitcherById(int pitcherId)
    {
        return _database.GetPitcherById(pitcherId);
    }

    public PitcherPitches GetPitchesByPitcherId(int pitcherId)
    {
        return _database.GetPitchesByPitcherId(pitcherId);
    }

    public PitcherStats GetPitcherStatsById(int pitcherId)
    {
        return _database.GetPitcherStatsById(pitcherId);
    }

    public List<Game> GetAllGames(int? gameId, int? homeTeamId, int? awayTeamId, string? season)
    {
        return _database.GetAllGames(gameId, homeTeamId, awayTeamId, season);
    }
    public Game GetGamesById(int? gameId, int? homeTeamId, int? awayTeamId, string? season)
    {
        return _database.GetGamesById(gameId, homeTeamId, awayTeamId, season);
    }
}