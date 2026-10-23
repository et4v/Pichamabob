# Backend API

.NET 8 web API over a MySQL database of pitches, pitchers and games. Written by James Nguyen and
Jackson Reed (originally at [jtnguyen3/hackMT11](https://github.com/jtnguyen3/hackMT11)).

## Running locally

1. Install the [.NET 8 SDK](https://dotnet.microsoft.com/download).
2. Copy `hackmt/.env.example` to `hackmt/.env` and fill in the details of a MySQL database
   (**never commit `.env`**). The hackathon database belonged to the original backend authors and
   isn't available, so you'll need your own MySQL server with the `pitch`, `player` and game tables
   that `Data/Database.cs` queries.
3. Start the server. It listens on port 5000:
   ```bash
   cd backend/hackmt
   dotnet run
   ```
4. To reach it from a phone, expose it with [ngrok](https://ngrok.com/) using **your own** free auth token:
   ```bash
   ngrok config add-authtoken <your-token>
   ngrok http 5000
   ```
   Put the `https://….ngrok-free.dev` URL that ngrok prints into `apiBaseURL` in the iOS app.

## Endpoints

| Method | Path | Returns |
|---|---|---|
| GET | `/ping` | `pong` (health check) |
| GET | `/pitches` | Every pitch, with pitcher and batter info |
| GET | `/pitchers` | Every pitcher |
| GET | `/pitchers/{id}` | One pitcher |
| GET | `/pitchers/{id}/pitches` | That pitcher's pitches |
| GET | `/pitchers/{id}/stats` | Stats by pitch type |
| GET | `/games` | Games (optional query: `gameId`, `homeTeamId`, `awayTeamId`, `season`) |
| GET | `/games/{gameId}` | One game |

## Code

| Folder | Purpose |
|---|---|
| `hackmt/Controllers/` | HTTP routes |
| `hackmt/Services/` | Thin layer between controllers and data access |
| `hackmt/Data/Database.cs` | MySQL queries (connection details come from `.env`) |
| `hackmt/Models/` | Response shapes |
