using Microsoft.AspNetCore.Mvc;
using System.Data.Common;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

public class GameController : Controller
{
    private readonly Service _gameService;
    
    public GameController(Service gameService)
    {
        _gameService = gameService;
    }

    [HttpGet]
    [Route("games")]
    public async Task<IActionResult> GetAllGames(int? gameId, int? homeTeamId, int? awayTeamId, string? season)
    {
        var games = _gameService.GetAllGames(gameId, homeTeamId, awayTeamId, season);
        return Ok(games);
    }
    
    [HttpGet]
    [Route("games/{gameId}")]
    public async Task<IActionResult> GetGamesById(int? gameId, int? homeTeamId, int? awayTeamId, string? season)
    {
        var games = _gameService.GetGamesById(gameId, homeTeamId, awayTeamId, season);
        if (games == null)
        {
            return NotFound();
        }
        return Ok(games);
    }
}