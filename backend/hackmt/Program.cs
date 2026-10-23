using DotNetEnv;
using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.Hosting;

namespace HackMT2026
{
    public class Program
    {
        public static void Main(string[] args)
        {
            // Load environment variables
            Env.Load();

            var builder = WebApplication.CreateBuilder(args);
            builder.Services.AddControllers();
            builder.Services.AddScoped<Service>();
            builder.Services.AddScoped<Database>();
            
            var app = builder.Build();

            app.UseRouting();
            
            app.MapControllers();
            
            // Basic test endpoint
            app.MapGet("/ping", () => "pong");

            app.Run("http://0.0.0.0:5000");
        }
    }
}
