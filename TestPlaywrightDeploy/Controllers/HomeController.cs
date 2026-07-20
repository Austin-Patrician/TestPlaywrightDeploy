using System.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using TestPlaywrightDeploy.Models;

namespace TestPlaywrightDeploy.Controllers;

public class HomeController : Controller
{
    public IActionResult Index()
    {
        return View();
    }

    public IActionResult Privacy()
    {
        return View();
    }

    public IActionResult ExportDemo()
    {
        return View();
    }

    [HttpPost]
    public async Task<IActionResult> ExportPdf([FromBody] ExportRequest request)
    {
        if (string.IsNullOrEmpty(request?.Url))
            return BadRequest("URL is required");

        try
        {
            // 设置 Playwright 浏览器路径环境变量
            var playwrightDir = Environment.GetEnvironmentVariable("PLAYWRIGHT_BROWSERS_PATH");

            using var playwright = await Microsoft.Playwright.Playwright.CreateAsync();
            await using var browser = await playwright.Chromium.LaunchAsync(new Microsoft.Playwright.BrowserTypeLaunchOptions
            {
                Headless = true,
                Args = new[]
                {
                    "--no-sandbox",
                    "--disable-setuid-sandbox",
                    "--disable-dev-shm-usage",
                    "--disable-gpu"
                }
            });

            var page = await browser.NewPageAsync();
            await page.SetViewportSizeAsync(1280, 900);

            await page.GotoAsync(request.Url, new Microsoft.Playwright.PageGotoOptions
            {
                WaitUntil = Microsoft.Playwright.WaitUntilState.NetworkIdle,
                Timeout = 30000
            });

            var pdfBytes = await page.PdfAsync(new Microsoft.Playwright.PagePdfOptions
            {
                Format = "A4",
                PrintBackground = true,
                Margin = new Microsoft.Playwright.Margin { Top = "20px", Bottom = "20px", Left = "20px", Right = "20px" },
                DisplayHeaderFooter = true,
                HeaderTemplate = "<div style='font-size:10px;text-align:center;width:100%;color:#888;'>TestPlaywrightDeploy - Export Demo</div>",
                FooterTemplate = "<div style='font-size:10px;text-align:center;width:100%;color:#888;'>Page <span class='pageNumber'></span> of <span class='totalPages'></span></div>"
            });

            return File(pdfBytes, "application/pdf", "export-demo.pdf");
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { error = ex.Message });
        }
    }

    [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
    public IActionResult Error()
    {
        return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
    }
}

public class ExportRequest
{
    public string? Url { get; set; }
}