using Microsoft.AspNetCore.Mvc;
using System.Data.Common;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

public class PitchController : Controller
{
    private readonly Service _pitchService;

    public PitchController(Service pitchService)
    {
        _pitchService = pitchService;
    }

    [HttpGet]
    [Route("pitches")]
    public async Task<IActionResult> GetAllPitches()
    {
        var pitches = _pitchService.GetAllPitches();
        return Ok(pitches);
    }

    [HttpGet]
    [Route("pitchers")]
    public async Task<IActionResult> GetAllPitchers()
    {
        var pitchers = _pitchService.GetAllPitchers();
        return Ok(pitchers);
    }

    [HttpGet]
    [Route("pitchers/{pitcherId}")]
    public async Task<IActionResult> GetPitcherById(int pitcherId)
    {
        var pitcher = _pitchService.GetPitcherById(pitcherId);
        if (pitcher == null)
        {
            return NotFound();
        }
        return Ok(pitcher);
    }

    [HttpGet]
    [Route("pitchers/{pitcherId}/pitches")]
    public async Task<IActionResult> GetPitchesByPitcherId(int pitcherId)
    {
        var pitcherPitches = _pitchService.GetPitchesByPitcherId(pitcherId);
        return Ok(pitcherPitches);
    }
    
    [HttpGet]
    [Route("pitchers/{pitcherId}/stats")]
    public async Task<IActionResult> GetPitcherStatsById(int pitcherId)
    {
        var stats = _pitchService.GetPitcherStatsById(pitcherId);
        return Ok(stats);
    }
}