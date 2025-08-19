using Domain.Entities.DTOs;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Persistence.Context;

namespace Wheelzy.Controllers
{
    [ApiController]
    [Route("[controller]")]

    public class WeatherForecastController : ControllerBase
    {
        private static readonly string[] Summaries = new[]
        {
            "Freezing", "Bracing", "Chilly", "Cool", "Mild", "Warm", "Balmy", "Hot", "Sweltering", "Scorching"
        };

        private readonly ILogger<WeatherForecastController> _logger;

        public WeatherForecastController(ILogger<WeatherForecastController> logger)
        {
            _logger = logger;
        }


        [HttpGet]
        [Route("GetWeatherForecast")]
        public IEnumerable<WeatherForecast> Get()
        {
            return Enumerable.Range(1, 5).Select(index => new WeatherForecast
            {
                Date = DateOnly.FromDateTime(DateTime.Now.AddDays(index)),
                TemperatureC = Random.Shared.Next(-20, 55),
                Summary = Summaries[Random.Shared.Next(Summaries.Length)]
            })
            .ToArray();
        }




        [HttpGet]
        [Route("newEndpoint")]


        public List<CarListingDto> GetCarListingsWithCurrentBuyerAndStatus()
        {
            using (var context = new CarSalesDbContext())
            {
                return context.CarListings
                    .Include(cl => cl.SubModel)
                        .ThenInclude(sm => sm.Model)
                            .ThenInclude(m => m.Make)
                    .Include(cl => cl.ZipCode)
                    .Include(cl => cl.CurrentStatus)
                    .Include(cl => cl.CurrentBuyer)
                    .Select(cl => new CarListingDto
                    {
                        CarListingID = cl.CarListingID,
                        MakeName = cl.SubModel.Model.Make.MakeName,
                        ModelName = cl.SubModel.Model.ModelName,
                        SubModelName = cl.SubModel.SubModelName,
                        CarYear = cl.CarYear,
                        ZipCode = cl.ZipCode.ZipCodeName,
                        CurrentBuyer = cl.CurrentBuyer != null ? cl.CurrentBuyer.BuyerName : null,
                        CurrentQuote = cl.CurrentBuyer != null
                            ? context.BuyerZipCodeQuotes
                                .Where(bzq => bzq.BuyerID == cl.CurrentBuyerID &&
                                             bzq.ZipCodeID == cl.ZipCodeID &&
                                             bzq.IsCurrentQuote)
                                .Select(bzq => bzq.QuoteAmount)
                                .FirstOrDefault()
                            : (decimal?)null,
                        CurrentStatus = cl.CurrentStatus.StatusName,
                        StatusDate = context.StatusHistories
                            .Where(sh => sh.CarListingID == cl.CarListingID &&
                                       sh.StatusID == cl.CurrentStatusID)
                            .OrderByDescending(sh => sh.StatusDate)
                            .Select(sh => sh.StatusDate)
                            .FirstOrDefault()
                    })
                    .ToList();
            }
        }



    }
}
