using MySql.Data.MySqlClient;
using HackMT2026.Models;
public class Database
{
    public static MySqlConnection GetConnection()
    {
        var connStr =
            $"Server={Environment.GetEnvironmentVariable("ENDPOINT")};" +
            $"Database={Environment.GetEnvironmentVariable("DB_NAME")};" +
            $"User ID={Environment.GetEnvironmentVariable("USER_ID")};" +
            $"Password={Environment.GetEnvironmentVariable("PASSWORD")};" +
            $"SslMode=Preferred;";

        return new MySqlConnection(connStr);
    }

    public List<PitchDto> GetAllPitches()
    {
        using var conn = GetConnection();
        conn.Open();

        var cmd = new MySqlCommand();
        cmd.Connection = conn;

        // Base SQL
        string cmdString = @"
            SELECT 
                pi.pitchNumber,
                pi.gameID,
                pi.pitchType,
                pi.coachCall,
                pi.actualCall,
                pi.outcome,
                pl_pitcher.playerID AS pitcherID,
                pl_pitcher.fName AS pitcherFirstName,
                pl_pitcher.lName AS pitcherLastName,
                pl_pitcher.playerNumber AS pitcherNumber,
                pl_batter.playerID AS batterID,
                pl_batter.fName AS batterFirstName,
                pl_batter.lName AS batterLastName,
                pl_batter.playerNumber AS batterNumber
            FROM pitch pi
            JOIN player pl_pitcher ON pi.pitcherID = pl_pitcher.playerID
            JOIN player pl_batter ON pi.batterID = pl_batter.playerID
            WHERE 1=1
        ";

        cmd.CommandText = cmdString;
        var pitches = new List<PitchDto>();
        using var reader = cmd.ExecuteReader();
        while (reader.Read())
            {
                pitches.Add(new PitchDto
                {
                    // Pitch info
                    PitchNumber = reader.GetInt32("pitchNumber"),
                    GameID = reader.GetInt32("gameID"),
                    PitchType = reader.GetString("pitchType"),
                    CoachCall = reader.GetInt32("coachCall"),
                    ActualCall = reader.GetInt32("actualCall"),
                    Outcome = reader.GetString("outcome"),

                    // Pitcher info
                    PitcherID = reader.GetInt32("pitcherID"),
                    PitcherFirstName = reader.GetString("pitcherFirstName"),
                    PitcherLastName = reader.GetString("pitcherLastName"),
                    PitcherNumber = reader.GetInt32("pitcherNumber"),

                    // Batter info
                    BatterID = reader.GetInt32("batterID"),
                    BatterFirstName = reader.GetString("batterFirstName"),
                    BatterLastName = reader.GetString("batterLastName"),
                    BatterNumber = reader.GetInt32("batterNumber")
                });
            }

        return pitches;
    }

    public List<Pitcher> GetAllPitchers()
    {
        var pitchers = new List<Pitcher>();

        using var conn = Database.GetConnection();
        conn.Open();

        using var cmd = new MySqlCommand();
        cmd.Connection = conn;

        string cmdString = @"
            SELECT DISTINCT
                p.playerID,
                p.fName,
                p.lName,
                p.playerNumber,
                t.teamName,
                t.season,
                t.ageGroup
            FROM player p
            JOIN pitch pi ON pi.pitcherID = p.playerID
            JOIN playerTeam pt
                ON p.playerID = pt.playerID
            JOIN team t
                ON t.teamID = pt.teamID
            AND t.season = pt.season
            JOIN (
                SELECT
                    playerID,
                    MAX(season) AS latestSeason
                FROM playerTeam
                GROUP BY playerID
            ) latest
                ON latest.playerID = pt.playerID
            AND latest.latestSeason = pt.season
            ";

        cmdString += " ORDER BY p.lName, p.fName";
        cmd.CommandText = cmdString;

        using var reader = cmd.ExecuteReader();

        while (reader.Read())
        {
            pitchers.Add(new Pitcher
            {
                PlayerId = reader.GetInt32("playerID"),
                FName = reader.GetString("fName"),
                LName = reader.GetString("lName"),
                PlayerNumber = reader.GetInt32("playerNumber"),
                TeamName = reader.GetString("teamName"),
                Season = reader.GetInt32("season"),
                AgeGroup = reader.GetString("ageGroup")
            });
        }

        return pitchers;
    }

    public Pitcher GetPitcherById(int pitcherId)
    {
        using var conn = GetConnection();
        conn.Open();

        var cmd = new MySqlCommand();
        cmd.Connection = conn;

        string cmdString = @"
            SELECT DISTINCT
                p.playerID,
                p.fName,
                p.lName,
                p.playerNumber,
                t.teamName,
                t.season,
                t.ageGroup
            FROM player p
            JOIN pitch pi ON pi.pitcherID = p.playerID
            JOIN playerTeam pt
                ON p.playerID = pt.playerID
            JOIN team t
                ON t.teamID = pt.teamID
            AND t.season = pt.season
            JOIN (
                SELECT
                    playerID,
                    MAX(season) AS latestSeason
                FROM playerTeam
                GROUP BY playerID
            ) latest
                ON latest.playerID = pt.playerID
            AND latest.latestSeason = pt.season
            WHERE p.playerID = @pitcherId
            LIMIT 1
        ";

        cmd.CommandText = cmdString;
        cmd.Parameters.AddWithValue("@pitcherId", pitcherId);

        using var reader = cmd.ExecuteReader();

        if (reader.Read())
        {
            return new Pitcher
            {
                PlayerId = reader.GetInt32("playerID"),
                FName = reader.GetString("fName"),
                LName = reader.GetString("lName"),
                PlayerNumber = reader.GetInt32("playerNumber"),
                TeamName = reader.GetString("teamName"),
                Season = reader.GetInt32("season"),
                AgeGroup = reader.GetString("ageGroup")
            };
        }

        return null;
    }

    public PitcherPitches GetPitchesByPitcherId(int pitcherId)
    {
        PitcherPitches pitcherPitches = new PitcherPitches();

        using var conn = Database.GetConnection();
        conn.Open();

        using var cmd = new MySqlCommand();
        cmd.Connection = conn;

        string cmdString = @"
                SELECT 
                    pi.*,
                    pl.fName,
                    pl.lName,
                    pl.playerNumber,
                    t.teamName,
                    t.season,
                    t.ageGroup
                FROM pitch pi
                JOIN player pl 
                    ON pi.pitcherId = pl.playerId
                JOIN game g 
                    ON pi.gameId = g.gameId
                JOIN team t
                    ON (t.teamId = g.homeTeamId AND t.season = g.homeTeamSeason)
                    OR (t.teamId = g.awayTeamId AND t.season = g.awayTeamSeason)
                WHERE pi.pitcherId = @pitcherId;
        ";

        cmd.CommandText = cmdString;
        cmd.Parameters.AddWithValue("@pitcherId", pitcherId);

        using var reader = cmd.ExecuteReader();
        bool pitcherSet = false;

        while (reader.Read())
        {
            // Only set pitcher info once
            if (!pitcherSet)
            {
                pitcherPitches.PlayerId = pitcherId;
                pitcherPitches.FirstName = reader.GetString("fName");
                pitcherPitches.LastName = reader.GetString("lName");
                pitcherPitches.PlayerNumber = reader.GetInt32("playerNumber");
                pitcherPitches.TeamName = reader.GetString("teamName");
                pitcherPitches.Season = reader.GetString("season");
                pitcherPitches.AgeGroup = reader.GetString("ageGroup");

                pitcherSet = true;
            }

            // Always add pitch info
            var pitch = new Pitch
            {
                PitchNumber = reader.GetInt32("pitchNumber"),
                PitcherId = reader.GetInt32("pitcherId"),
                GameId = reader.GetInt32("gameId"),
                PitchType = reader.GetString("pitchType"),
                CoachCall = reader.GetInt32("coachCall"),
                ActualCall = reader.GetInt32("actualCall"),
                Outcome = reader.GetString("outcome"),
                BatterId = reader.GetInt32("batterId")
            };

            pitcherPitches.PitchData.Add(pitch);
        }

        return pitcherPitches;
    }

    public PitcherStats GetPitcherStatsById(int pitcherId)
    {
        var pitcherStats = new PitcherStats();
        List<PitchInstance> pitchInstances = new List<PitchInstance>();

        using var conn = GetConnection();
        conn.Open();

        var cmd = new MySqlCommand();
        cmd.Connection = conn;

        string cmdString = @"
            SELECT 
                pi.*,
                pl.fName,
                pl.lName,
                pl.playerNumber,
                t.teamName,
                t.season,
                t.ageGroup
            FROM pitch pi
            JOIN player pl 
                ON pi.pitcherId = pl.playerId
            JOIN game g 
                ON pi.gameId = g.gameId
            JOIN team t
                ON (t.teamId = g.homeTeamId AND t.season = g.homeTeamSeason)
                OR (t.teamId = g.awayTeamId AND t.season = g.awayTeamSeason)
            WHERE pi.pitcherId = @pitcherId;
        ";

        cmd.CommandText = cmdString;
        cmd.Parameters.AddWithValue("@pitcherId", pitcherId);

        using var reader = cmd.ExecuteReader();
        bool pitcherSet = false;

        while (reader.Read())
        {
            if (!pitcherSet)
            {
                pitcherStats.PlayerId = pitcherId;
                pitcherStats.FirstName = reader.GetString("fName");
                pitcherStats.LastName = reader.GetString("lName");
                pitcherStats.PlayerNumber = reader.GetInt32("playerNumber");
                pitcherStats.TeamName = reader.GetString("teamName");
                pitcherStats.Season = reader.GetString("season");
                pitcherStats.AgeGroup = reader.GetString("ageGroup");

                pitcherSet = true;
            }

            int coachCall = reader.GetInt32("coachCall");
            int actualCall = reader.GetInt32("actualCall");
            
            pitchInstances.Add(new PitchInstance
            {
                PitchType = reader.GetString("pitchType"),
                Outcome = reader.GetString("outcome"),
                IsAccurate = coachCall == actualCall
            });
        }

        foreach (var pi in pitchInstances)
        {
            if (!pitcherStats.PitchTypes.ContainsKey(pi.PitchType))
            {
                pitcherStats.PitchTypes[pi.PitchType] = new PitchTypeStats();
            }

            switch (pi.Outcome.ToLower())
            {
                case "strike":
                    pitcherStats.PitchTypes[pi.PitchType].Strikes++;
                    break;
                case "ball":
                    pitcherStats.PitchTypes[pi.PitchType].Balls++;
                    break;
                case "foul":
                    pitcherStats.PitchTypes[pi.PitchType].Fouls++;
                    break;
                case "inplay":
                    pitcherStats.PitchTypes[pi.PitchType].InPlay++;
                    break;
            }

            if (pi.IsAccurate)
            {
                pitcherStats.TotalAccurate++;
            }

            pitcherStats.TotalPitches++;
        }

        return pitcherStats;
    }

    public List<Game> GetAllGames(int? gameId, int? homeTeamId, int? awayTeamId, string? season)
    {
        var games = new List<Game>();

        using var conn = GetConnection();
        conn.Open();

        var cmd = new MySqlCommand();
        cmd.Connection = conn;

        string cmdString = @"
            SELECT 
                g.gameId,
                g.gameDate,
                

                -- Home team info
                home.teamId AS HomeTeamId,
                home.season AS HomeTeamSeason,
                home.teamName AS HomeTeamName,
                home.ageGroup AS HomeAgeGroup,

                -- Away team info
                away.teamId AS AwayTeamId,
                away.season AS AwayTeamSeason,
                away.teamName AS AwayTeamName,
                away.ageGroup AS AwayAgeGroup
            FROM game g
            JOIN team home 
                ON g.homeTeamId = home.teamId 
            AND g.homeTeamSeason = home.season
            JOIN team away
                ON g.awayTeamId = away.teamId 
            AND g.awayTeamSeason = away.season
            WHERE 1=1
        ";

        if (gameId.HasValue)
        {
            cmdString += " AND g.gameId = @gameId";
            cmd.Parameters.AddWithValue("@gameId", gameId.Value);
        }
        if (homeTeamId.HasValue)
        {
            cmdString += " AND g.homeTeamId = @homeTeamId";
            cmd.Parameters.AddWithValue("@homeTeamId", homeTeamId.Value);
        }

        if (awayTeamId.HasValue)
        {
            cmdString += " AND g.awayTeamId = @awayTeamId";
            cmd.Parameters.AddWithValue("@awayTeamId", awayTeamId.Value);
        }

        if (!string.IsNullOrWhiteSpace(season))
        {
            cmdString += " AND (g.homeTeamSeason = @season OR g.awayTeamSeason = @season)";
            cmd.Parameters.AddWithValue("@season", season);
        }

        cmd.CommandText = cmdString;

        using var reader = cmd.ExecuteReader();

        while (reader.Read())
        {
            games.Add(new Game
            {
                GameId = reader.GetInt32("gameId"),
                GameDate = reader.GetString("gameDate"),

                // Home team
                HomeTeamId = reader.GetInt32("HomeTeamId"),
                HomeTeamSeason = reader.GetString("HomeTeamSeason"),
                HomeTeamName = reader.GetString("HomeTeamName"),
                HomeAgeGroup = reader.GetString("HomeAgeGroup"),

                // Away team
                AwayTeamId = reader.GetInt32("AwayTeamId"),
                AwayTeamSeason = reader.GetString("AwayTeamSeason"),
                AwayTeamName = reader.GetString("AwayTeamName"),
                AwayAgeGroup = reader.GetString("AwayAgeGroup")
            });
        }

        return games;
    }

    public Game GetGamesById(int? gameId, int? homeTeamId, int? awayTeamId, string? season)
    {
        using var conn = GetConnection();
        conn.Open();

        var cmd = new MySqlCommand();
        cmd.Connection = conn;

        string cmdString = @"
            SELECT 
                g.gameId,
                g.gameDate,
                
                home.teamId AS HomeTeamId,
                home.season AS HomeTeamSeason,
                home.teamName AS HomeTeamName,
                home.ageGroup AS HomeAgeGroup,

                away.teamId AS AwayTeamId,
                away.season AS AwayTeamSeason,
                away.teamName AS AwayTeamName,
                away.ageGroup AS AwayAgeGroup
            FROM game g
            JOIN team home 
                ON g.homeTeamId = home.teamId 
            AND g.homeTeamSeason = home.season
            JOIN team away
                ON g.awayTeamId = away.teamId 
            AND g.awayTeamSeason = away.season
            WHERE g.gameId = @gameId
        ";

        cmd.CommandText = cmdString;
        cmd.Parameters.AddWithValue("@gameId", gameId);

        using var reader = cmd.ExecuteReader();

        if (reader.Read())
        {
            return new Game
            {
                GameId = reader.GetInt32("gameId"),
                GameDate = reader.GetString("gameDate"),

                HomeTeamId = reader.GetInt32("HomeTeamId"),
                HomeTeamSeason = reader.GetString("HomeTeamSeason"),
                HomeTeamName = reader.GetString("HomeTeamName"),
                HomeAgeGroup = reader.GetString("HomeAgeGroup"),

                AwayTeamId = reader.GetInt32("AwayTeamId"),
                AwayTeamSeason = reader.GetString("AwayTeamSeason"),
                AwayTeamName = reader.GetString("AwayTeamName"),
                AwayAgeGroup = reader.GetString("AwayAgeGroup")
            };
        }

        return null;
    }
}