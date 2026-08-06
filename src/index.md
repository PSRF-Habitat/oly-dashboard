---
toc: false
theme: [dashboard, light]
header: "<a href='https://restorationfund.org'><img src='data/images/logo-transwhite.png' alt='Logo' style='height: 120px;'></a>"
pager: false
---

<!-- =================================================== -->
<!-- Flash cards -->
<!-- =================================================== -->
<!-- <div class="stats-grid">
  <div class="card">
    <h1 class="muted">Acres Restored</h1>
    <span class="big" style="color: #045B4C">141.3</span>
  </div>
  <div class="card">
    <h1 class="muted">Sites Visited</h1>
    <span class="big" style="color: #045B4C">777</span>
  </div>
  <div class="card">
    <h1 class="muted">Some Other</h1>
    <span class="big" style="color: #045B4C">222</span>
  </div>
  <div class="card">
    <h1 class="muted">Catchy Facts</h1>
    <span class="big" style="color: #045B4C">999</span>
  </div>
</div> -->
<!-- =================================================== -->
<!-- END Flash cards -->
<!-- =================================================== -->

<!-- --- -->

<!-- =================================================== -->
<!-- Intro text section -->
<!-- =================================================== -->
```html
<!-- Main container -->
<div id="intro-hero" style="
  border-radius: 16px;
  padding: 2rem;
  margin: 1rem 0 2rem 0;
">
  <!-- 3 card layout: 1 left, 2 right -->
  <div class="intro-hero-grid">
    <!-- LEFT: title + intro text card -->
    <div class="intro-panel">
      <h1 style="margin-top:0; color:#045B4C;">
        Mapping Olympia Oyster Restoration Across Puget Sound
      </h1>
      <p style="color:#333; margin-bottom:0;">
        This map tracks over two decades of work to restore Puget Sound's only native oyster. Explore where we've added shell and oysters to build habitat and reestablish populations, where larvae are settling and growing into new oysters each year, and how populations have changed at individual sites over time.
      </p>
    </div>

    <!-- RIGHT: two stacked callout cards -->
    <div>
      <div class="intro-card intro-card--enhancement" style="margin-bottom:1.5rem;">
        <div class="intro-card-label" style="color:#045B4C; font-size:1rem;">
          Enhancement Sites
        </div>
        <p>
          Places where we've added shell, juvenile, or adult oysters to build habitat and reestablish populations.
        </p>
      </div>

      <div class="intro-card intro-card--recruitment">
        <div class="intro-card-label" style="color:#045B4C; font-size:1rem;">
          Recruitment Monitoring
        </div>
        <p>
          Annual tracking of where and how many juvenile oysters are settling across the Sound.
        </p>
      </div>
    </div>
  </div>

  <!-- Tip container -->
  <div class="intro-tip">
    <span class="intro-tip-icon">💡</span>
    <span class="intro-tip-text">
      Use the <strong>tabs</strong> in the panel on the left of the map to switch between exploring
      <strong>enhancement projects</strong> and <strong>recruitment monitoring</strong>. In the
      Enhancement view, sites marked with an
      <span style="color:var(--marker-story); font-weight:600;">green dot</span>
      have a story — select one from the dropdown or click it directly. In the Recruitment view,
      click any station to see its settlement history.
    </span>
  </div>
</div>
```

```js
// ===================================================
// LOAD DATA
// ===================================================

// Enhancement sites metadata for map points and tooltips
const enh_sites_metadata = await FileAttachment("data/enhancement_sites_metadata.csv").csv({typed: true});

// Recruitment data
const recruitment_data = (await FileAttachment("data/recruitment_unfiltered.csv").csv({typed: true}))
    .map(d => ({...d, index: (d.index === "NA" || d.index === null || d.index === "") ? null : +d.index}));

// Data for timeline
const timeline_data = await FileAttachment("data/timeline_data.csv").csv({typed: true});

// Fidalgo Bay population estimates
const fidalgo_pop_est = await FileAttachment("data/fidalgo_population_estimates.csv").csv({typed: true});

// Fidalgo Bay shell height
const fidalgo_heights = await FileAttachment("data/fidalgo_heights_2023.csv").csv({typed: true});

// Oyster Bay population estimates
const oysterbay_pop_est = await FileAttachment("data/oysterbay_population_estimates.csv").csv({typed: true});

// Oyster Bay shell height
const oysterbay_heights = await FileAttachment("data/oysterbay_2026_heights.csv").csv({typed: true});

// Chico Bay density estimates
const chicobay_dens_est = await FileAttachment("data/chicobay_density_estimates.csv").csv({typed: true});

// Chico Bay shell height
const chicobay_heights = await FileAttachment("data/chicobay_2021_heights.csv").csv({typed: true});

// ===================================================
// IMPORT LIBRARIES
// ===================================================
import * as L from "npm:leaflet@1.9.4";

// ===================================================
// SET GLOBAL STATES
// ===================================================
window.selectedSite = null;
window.markersBySite = {};

// ===================================================
// MAP CONFIGURATION
// Where to center and zoom map to
// ===================================================
const center = [47.85, -122.7];
const zoom = 8;

// ===================================================
// SITES THAT HAVE FULL STORY PANELS
// This is a list of all sites that have a written story
// To add a new story site, add its name here AND
// add a case in buildSitePanel() below.
// ===================================================
const story_sites = new Set([
  "Fidalgo Bay",
  "Oyster Bay",
  "Chico Bay",
  //   "Silverdale",
  // Add more here as stories are written
]);

// ===================================================
// PHOTOS
// ===================================================

// Tooltip photos
const tooltipPhotos = {
  "Port Gamble Bay":  FileAttachment("data/images/portgamble_tooltip.jpg").href,
  "Quilcene Bay":     FileAttachment("data/images/quilcene_tooltip.jpg").href,
  "Sinclair Inlet":   FileAttachment("data/images/sinclair_tooltip.jpg").href,
  "Legion Park":      FileAttachment("data/images/legion_SAMPLE_tooltip.jpg").href,
  "Fidalgo Bay":      FileAttachment("data/images/fidalgo_tooltip.jpeg").href,
  "Chico Bay":        FileAttachment("data/images/chicobay_tooltip.jpg").href,
  "Dogfish Bay":      FileAttachment("data/images/dogfish_tooltip.jpg").href,
  "Kiket and Lone Tree Lagoons": FileAttachment("data/images/lonetree.jpg").href,
  "Liberty Bay":      FileAttachment("data/images/libertybay_tooltip.jpg").href,
  "Oyster Bay":       FileAttachment("data/images/oysterbay_tooltip.jpg").href,
  "Samish Bay":       FileAttachment("data/images/samish_tooltip.jpg").href,
  "Scanida":          FileAttachment("data/images/scandia_tooltip.jpg").href,
  "Silverdale":       FileAttachment("data/images/silverdale_tooltip.jpg").href,
  "Smith Cove":       FileAttachment("data/images/smithcove_tooltip.jpg").href,
  "Drayton Harbor":   FileAttachment("data/images/drayton_tooltip.jpg").href,
  // Add more here
};

// Cover photo for hero
const coverPhoto = FileAttachment("data/images/cover.jpg").href;

const introHero = document.querySelector("#intro-hero");
if (introHero) {
  introHero.style.backgroundImage = `url(${coverPhoto})`;
}

// // Header photo
// const headerPhoto = FileAttachment("data/images/samish_tooltip.jpg").href;
// const header = document.querySelector("#observablehq-header");
// if (header) {
//   header.style.backgroundImage = `url(${headerPhoto})`;
// }


// ===================================================
// ===================================================
// MAP ICONS
// - Enhancement sites
// - Enhancement sites with stories
// ===================================================
// ===================================================

// --- Enhancement: standard ---
const enhancementIcon = L.divIcon({
  className: '',
  html: `<div style="
    background-color: var(--marker-standard);
    width: 14px;
    height: 14px;
    border-radius: 50%;
    border: 2px solid var(--marker-stroke);
    box-shadow: 0 0 4px #939393;
  "></div>`,
  iconSize: [18, 18],
  iconAnchor: [9, 9]
});

// --- Enhancement: story site ---
const enhancementStoryIcon = L.divIcon({
  className: '',
  html: `<div style="
    background-color: var(--marker-story);
    width: 14px;
    height: 14px;
    border-radius: 50%;
    border: 2px solid var(--marker-stroke);
    box-shadow: 0 0 4px #939393;
  "></div>`,
  iconSize: [18, 18],
  iconAnchor: [9, 9]
});

// ===================================================
// ===================================================
// SHARED FUNCTION: CAROUSEL
// Used by every site panel that has photos
// Pass the container div and an array of image URLs
// Creates scroll buttons and dots for photo count
// ===================================================
// ===================================================
function buildCarousel(container, photos, captions = []) {
    // If no photos, leave the container empty
    if(!photos || photos.length === 0) return;

    container.innerHTML = `
        <div class="carousel" style="margin-bottom: 32px;">
            <!-- Previous photo button -->
            <button class="carousel-btn prev">‹</button>

            <div class="carousel-images">
                ${photos.map((url, i) =>
                  // For each photo URL, it creates an <img> tag.
                  // The first image gets the class "active" (i === 0 means index is 0)
                  `<div class="carousel-slide ${i === 0 ? 'active' : ''}">
                        <img src="${url}" class="carousel-image">
                        ${captions[i] ? `<div class="carousel-caption">${captions[i]}</div>` : ''}
                    </div>`
                // Stitch all the generated <img> strings together
                ).join('')}
            </div>

            <!-- Next photo button -->
            <button class="carousel-btn next">›</button>

            <div class="carousel-dots"></div>
         </div>
    `;
    // Find all <img> elements inside this container that have the class "carousel-image"
    const slides = container.querySelectorAll('.carousel-slide');

    const dotsContainer = container.querySelector('.carousel-dots');

    // Track which image is currently showing. Starts at 0 (the first image)
    let currentIndex = 0;

    // Loop over each image by its index to create one dot per photo
    slides.forEach((_, i) => {
        const dot = document.createElement('span');
        // This is a shorthand for if/else: condition ? value_if_true : value_if_false
        // Same as: if i == 0: 'carousel-dot active' else: 'carousel-dot'
        dot.className = 'carousel-dot' + (i === 0 ? ' active' : '');

        // When this dot is clicked, call showImage() with this dot's index
        dot.onclick = () => showImage(i);

        // Add the dot element to the dots container div on the page.
        dotsContainer.appendChild(dot);
    });

    const dots = container.querySelectorAll('.carousel-dot');

    // ----------------------------------------------
    // Function to switch which image is visible, called when prev or next is clicked
    // ----------------------------------------------   
    function showImage(index) {
        // Remove active class from whicever image is currently showing
        slides[currentIndex].classList.remove('active');

        // Also remove active from currently lit up dot
        dots[currentIndex].classList.remove('active');

        // Update currentIndex to the new image we want to show
        currentIndex = index;

        // Add active class to the new image
        slides[currentIndex].classList.add('active');

        // Also add active class to the new dot
        dots[currentIndex].classList.add('active');
    }

    // Wire up the prev button (.onclick sets what happens when it's clicked)
    container.querySelector('.prev').onclick = () => {
        // Wraps around, so if we are on 0 and go back it will go to the last image
        showImage((currentIndex - 1 + slides.length) % slides.length);
    };

    // Wire up the next button
    container.querySelector('.next').onclick = () => {
        showImage((currentIndex + 1) % slides.length);
    };
} // END CAROUSEL BUILDER FUNCTION


// ===================================================
// ===================================================
// SHARED FUNCTION: POPULATION + TIMELINE COMBINED PLOT
// Overlays enhancement timeline onto a site's population chart
// Uses custom built tooltip - might change later
// ===================================================
// ===================================================
function createPopulationTimelinePlot(popData, timelineData, siteName) {
    // Remove any rows with missing population values
    const cleanPop = (popData || []).filter(
        d => d.population_estimate != null && d.population_estimate !== "NA"
    );
    // If there is no population estimates, do not make a chart
    if (cleanPop.length === 0) return null;

    // Find all timeline events that belong to this site and sort chronologically
    const events = (timelineData || [])
        .filter(d => d.site === siteName && d.year)
        .sort((a, b) => a.year - b.year);

    // Use largest pop estimate to set y axis limit + 8% for a little buffer
    const maxPop = Math.max(...cleanPop.map(d => d.population_estimate));
    const yMax = maxPop * 1.08;


    // ---------------------------------------------------
    // Position Timeline Markers
    // ---------------------------------------------------
    // Each restoration action gets a vertical dashed line.

    // How far above the data point every line extends,
    // as a fraction of the y-axis max
    const LINE_LENGTH_FRACTION = 0.5;

    // No line may cross this fraction of yMax, 
    // so a line starting near the top of the population
    // curve doesn't cross chart edge
    const MAX_TOP_FRACTION = 0.94;

    const eventsWithY = events.map((event) => {
        // Try to find population data from the exact same year as the timeline action
        let match = cleanPop.find(p => p.year === event.year);
        // If there is no pop value that year, find closest available year instead
        if (!match) {
            match = cleanPop.reduce((closest, p) =>
                Math.abs(p.year - event.year) < Math.abs(closest.year - event.year) ? p : closest
            , cleanPop[0]);
        }
        // Store the population value closest to the event year
        const popAtYear = match ? match.population_estimate : 0;

        // Line height
        const desiredY2 = popAtYear + (yMax * LINE_LENGTH_FRACTION);

        // Clamp line height so it doesn't exceed top of chart
        const y2 = Math.min(desiredY2, yMax * MAX_TOP_FRACTION);

        // Return the original timeline information plus the calculated positions needed for plotting
        return { ...event, popAtYear, y2 };
    });

    // -----------------------------------------------
    // Build the main chart with Plot
    // -----------------------------------------------
    const chart = Plot.plot({
        height: 380, // Overall chart size
        marginLeft: 60,
        marginRight: 30,
        marginTop: 15,
        marginBottom: 30,
        insetBottom: 20, // chart padding
        insetTop: 10,
        // X-axis (years)
        x: {
            label: null,
            tickFormat: "d",
            tickSpacing: 60,
            padding: 0.1,
            insetLeft: 10,
            insetRight: 10
        },
        // Y-axis (population)
        y: {
            label: "Estimated Population",
            grid: true,
            // Set range from 0 to maximum population
            domain: [0, yMax],
            // Format large numbers:
            // 1000 = 1K
            // 1000000 = 1M
            tickFormat: d => {
                if (d >= 1_000_000) return (d / 1_000_000).toFixed(1) + "M";
                if (d >= 1_000)     return (d / 1_000).toFixed(0) + "K";
                return d;
            }
        },
        marks: [
            // Light green shaded area below population trend
            Plot.areaY(cleanPop, {
                x: "year",
                y: "population_estimate",
                fill: "#045B4C",
                fillOpacity: 0.08
            }),
            // Dashed vertical lines showing enhancement actions
            Plot.ruleX(eventsWithY, {
                x: "year",
                y1: "popAtYear",
                y2: "y2",
                stroke: "#999",
                strokeWidth: 2,
                strokeDasharray: "6,4",
                strokeOpacity: 0.85
            }),
            // Main population trend line
            Plot.line(cleanPop, {
                x: "year",
                y: "population_estimate",
                stroke: "#045B4C",
                strokeWidth: 2.5
            }),
            // Population estimate points
            Plot.dot(cleanPop, {
                x: "year",
                y: "population_estimate",
                fill: "#045B4C",
                stroke: "white",
                strokeWidth: 2,
                r: 4
            }),
            // Dots at the top of enhancement action markers
            Plot.dot(eventsWithY, {
                x: "year",
                y: "y2",
                r: 6,
                fill: "#999",
                stroke: "white",
                strokeWidth: 2
            })
        ],
        // Chart font styling
        style: { fontFamily: "inherit", fontSize: "14px", overflow: "visible" }
    });

    // ---------------------------------------------------
    // CREATE TOOLTIP CONTAINER
    // ---------------------------------------------------
    // Create a wrapper around the chart
    // (This lets us position tooltips relative to the chart)
    const wrapper = document.createElement("div");
    wrapper.style.position = "relative";
    wrapper.style.containerType = "inline-size";
    wrapper.appendChild(chart);

    // Create container for tooltip
    const tooltip = document.createElement("div");
    Object.assign(tooltip.style, {
        position: "absolute", // Place tooltip above chart
        display: "none", // Hidden until user hovers
        pointerEvents: "none", // Tooltip should not block mouse interactions
        background: "white",
        borderRadius: "10px",
        boxShadow: "0 4px 16px rgba(0,0,0,0.15)",
        padding: "0",
        zIndex: "20",
        transition: "opacity 0.1s ease",
        opacity: "0"
    });
    wrapper.appendChild(tooltip);

    // ---------------------------------------------------
    // TOOLTIP HTML BUILDERS
    // ---------------------------------------------------
    //
    // These functions create the content shown when
    // hovering over different types of points (pop estimates or enhancement actions)
    function buildEventTooltipHTML(event) {
        return `
            <div style="border-left:4px solid #999; border-radius:10px; overflow:hidden; width:clamp(260px, 46cqw, 380px);">
                <div style="padding:clamp(8px, 2cqw, 10px) clamp(14px, 4cqw, 18px);">
                    <div style="display:flex; align-items:baseline; gap:10px; margin-bottom:5px;">
                        <span style="font-size:clamp(12px, 3.2cqw, 15px); font-weight:700; color:#045B4C;">${event.year}</span>
                        <span style="font-size:clamp(10px, 2.4cqw, 12px); font-weight:600; color:#999; text-transform:uppercase; letter-spacing:0.4px;">${event.label || "Enhancement Action"}</span>
                    </div>
                    <p style="font-size:clamp(11px, 2.8cqw, 13px); line-height:1.4; color:#444; margin:0;">
                        ${event.description || "No description recorded."}
                    </p>
                </div>
            </div>
        `;
    }

    function buildPopulationTooltipHTML(point) {
        return `
            <div style="border-left:4px solid #045B4C; border-radius:10px; overflow:hidden; width:max-content; min-width:clamp(160px, 26cqw, 190px); max-width:clamp(210px, 34cqw, 260px);">
                <div style="padding:clamp(10px, 3cqw, 14px) clamp(11px, 3.3cqw, 16px);">
                    <div style="font-size:clamp(9px, 2.2cqw, 11px); font-weight:600; color:#045B4C; text-transform:uppercase; letter-spacing:0.4px; margin-bottom:4px; white-space:nowrap;">
                        Estimated Population
                    </div>
                    <div style="display:flex; align-items:baseline; gap:8px; white-space:nowrap;">
                        <span style="font-size:clamp(12px, 3.2cqw, 15px); font-weight:700; color:#222;">${point.year}</span>
                        <span style="font-size:clamp(12px, 3.2cqw, 15px); color:#444;">${point.population_estimate.toLocaleString()} oysters</span>
                    </div>
                </div>
            </div>
        `;
    }

    // ---------------------------------------------------
    // ADD HOVER INTERACTION
    // ---------------------------------------------------
    // Find the SVG element created by Observable Plot
    const svgEl = chart.tagName === "svg" ? chart : chart.querySelector("svg");

    // Get the chart's x and y conversion tools...
    // These convert data values (years/populations) into screen positions (pixels)
    const xScale = svgEl.scale ? svgEl.scale("x") : chart.scale("x");
    const yScale = svgEl.scale ? svgEl.scale("y") : chart.scale("y");
    const svgNS = "http://www.w3.org/2000/svg"; // Required for creating SVG elements

    // Function that creates an invisible clickable area over each point
    function addHoverPoint(datum, cx, cy, buildHTML) {
        // Create an invisible circle.
        // The user can hover over this even though the actual chart point is small
        const hitCircle = document.createElementNS(svgNS, "circle");
        hitCircle.setAttribute("cx", cx);
        hitCircle.setAttribute("cy", cy);
        hitCircle.setAttribute("r", 12); // Larger radius makes hovering easier
        hitCircle.setAttribute("fill", "transparent"); // Make invisible
        hitCircle.style.cursor = "pointer";
        svgEl.appendChild(hitCircle);

        // When mouse enters point:
        hitCircle.addEventListener("pointerenter", () => {
            // Fill tooltip with correct information
            tooltip.innerHTML = buildHTML(datum);
            // Show tooltip
            tooltip.style.display = "block";

            // Find point position on screen
            const pointRect = hitCircle.getBoundingClientRect();
            const wrapperRect = wrapper.getBoundingClientRect();
            // Convert position relative to chart container
            const px = pointRect.left + pointRect.width / 2 - wrapperRect.left;
            const py = pointRect.top + pointRect.height / 2 - wrapperRect.top;

            // Decide whether tooltip fits to the right or left
            const tw = tooltip.offsetWidth;
            const th = tooltip.offsetHeight;
            const OFFSET = 3; // How far away from point to start tooltip

            const spaceRight = wrapperRect.width - px;
            const spaceAbove = py;

            let left = spaceRight - OFFSET >= tw ? px + OFFSET : px - tw - OFFSET;
            let top = spaceAbove - OFFSET >= th ? py - th - OFFSET : py + OFFSET;

            // Clamp so the tooltip never spills outside the wrapper's bounds
            left = Math.max(4, Math.min(left, wrapperRect.width - tw - 4));
            top = Math.max(4, Math.min(top, wrapperRect.height - th - 4));

            tooltip.style.left = `${left}px`;
            tooltip.style.top = `${top}px`;
            tooltip.style.opacity = "0.88";
        });

        // Hide tooltip when user leaves point
        hitCircle.addEventListener("pointerleave", () => {
            tooltip.style.opacity = "0";
            tooltip.style.display = "none";
        });
    }
    // Add hover areas for population points
    cleanPop.forEach(p => {
        addHoverPoint(p, xScale.apply(p.year), yScale.apply(p.population_estimate), buildPopulationTooltipHTML);
    });

    // Add hover areas for enhancement actions
    eventsWithY.forEach(ev => {
        addHoverPoint(ev, xScale.apply(ev.year), yScale.apply(ev.y2), buildEventTooltipHTML);
    });

    return wrapper;
} // END POPULATION + TIMELINE COMBINED PLOT

// ===================================================
// ===================================================
// SHARED FUNCTION: DENSITY + TIMELINE COMBINED PLOT
// Overlays enhancement timeline onto a site's density chart
// Same as population, but with density estimates instead
// ===================================================
// ===================================================
function createDensityTimelinePlot(densData, timelineData, siteName) {
    // Remove any rows with missing density values
    const cleanDens = (densData || []).filter(
        d => d.density_estimate != null && d.density_estimate !== "NA"
    );
    // If there is no density estimates, do not make a chart
    if (cleanDens.length === 0) return null;

    // Find all timeline events that belong to this site and sort chronologically
    const events = (timelineData || [])
        .filter(d => d.site === siteName && d.year)
        .sort((a, b) => a.year - b.year);

    // Use largest dens estimate to set y axis limit + 8% for a little buffer
    const maxDens = Math.max(...cleanDens.map(d => d.density_estimate));
    const yMax = maxDens * 1.08;


    // ---------------------------------------------------
    // Position Timeline Markers
    // ---------------------------------------------------
    // Each restoration action gets a vertical dashed line.

    // How far above the data point every line extends,
    // as a fraction of the y-axis max
    const LINE_LENGTH_FRACTION = 0.5;

    // No line may cross this fraction of yMax, 
    // so a line starting near the top of the population
    // curve doesn't cross chart edge
    const MAX_TOP_FRACTION = 0.94;

    const eventsWithY = events.map((event) => {
        // Try to find density data from the exact same year as the timeline action
        let match = cleanDens.find(p => p.year === event.year);
        // If there is no dens value that year, find closest available year instead
        if (!match) {
            match = cleanDens.reduce((closest, p) =>
                Math.abs(p.year - event.year) < Math.abs(closest.year - event.year) ? p : closest
            , cleanDens[0]);
        }
        // Store the density value closest to the event year
        const densAtYear = match ? match.density_estimate : 0;

        // Line height
        const desiredY2 = densAtYear + (yMax * LINE_LENGTH_FRACTION);

        // Clamp line height so it doesn't exceed top of chart
        const y2 = Math.min(desiredY2, yMax * MAX_TOP_FRACTION);

        // Return the original timeline information plus the calculated positions needed for plotting
        return { ...event, densAtYear, y2 };
    });

    // -----------------------------------------------
    // Build the main chart with Plot
    // -----------------------------------------------
    const chart = Plot.plot({
        height: 380, // Overall chart size
        marginLeft: 60,
        marginRight: 30,
        marginTop: 15,
        marginBottom: 30,
        insetBottom: 20, // chart padding
        insetTop: 15,
        // X-axis (years)
        x: {
            label: null,
            tickFormat: "d",
            interval: 1,
            tickSpacing: 60,
            padding: 0.1,
            insetLeft: 10,
            insetRight: 10
        },
        // Y-axis (density)
        y: {
            label: "Estimated Density",
            grid: true,
            // Set range from 0 to maximum density
            domain: [0, yMax],
            // Format large numbers:
            // 1000 = 1K
            // 1000000 = 1M
            tickFormat: d => {
                if (d >= 1_000_000) return (d / 1_000_000).toFixed(1) + "M";
                if (d >= 1_000)     return (d / 1_000).toFixed(0) + "K";
                return d;
            }
        },
        marks: [
            // Light green shaded area below density trend
            Plot.areaY(cleanDens, {
                x: "year",
                y: "density_estimate",
                fill: "#045B4C",
                fillOpacity: 0.08
            }),
            // Dashed vertical lines showing enhancement actions
            Plot.ruleX(eventsWithY, {
                x: "year",
                y1: "densAtYear",
                y2: "y2",
                stroke: "#999",
                strokeWidth: 2,
                strokeDasharray: "6,4",
                strokeOpacity: 0.85
            }),
            // Main density trend line
            Plot.line(cleanDens, {
                x: "year",
                y: "density_estimate",
                stroke: "#045B4C",
                strokeWidth: 2.5
            }),
            Plot.ruleX(cleanDens, { // Error bars
                x: "year",
                y1: d => Math.max(0, d.density_estimate - d.std_err),
                y2: d => d.density_estimate + d.std_err,
                stroke: "#045B4C",
                strokeWidth: 1.5
                }),
            // Density estimate points
            Plot.dot(cleanDens, {
                x: "year",
                y: "density_estimate",
                fill: "#045B4C",
                stroke: "white",
                strokeWidth: 2,
                r: 4
            }),
            // Dots at the top of enhancement action markers
            Plot.dot(eventsWithY, {
                x: "year",
                y: "y2",
                r: 6,
                fill: "#999",
                stroke: "white",
                strokeWidth: 2
            })
        ],
        // Chart font styling
        style: { fontFamily: "inherit", fontSize: "14px", overflow: "visible" }
    });

    // ---------------------------------------------------
    // CREATE TOOLTIP CONTAINER
    // ---------------------------------------------------
    // Create a wrapper around the chart
    // (This lets us position tooltips relative to the chart)
    const wrapper = document.createElement("div");
    wrapper.style.position = "relative";
    wrapper.style.containerType = "inline-size";
    wrapper.appendChild(chart);

    // Create container for tooltip
    const tooltip = document.createElement("div");
    Object.assign(tooltip.style, {
        position: "absolute", // Place tooltip above chart
        display: "none", // Hidden until user hovers
        pointerEvents: "none", // Tooltip should not block mouse interactions
        background: "white",
        borderRadius: "10px",
        boxShadow: "0 4px 16px rgba(0,0,0,0.15)",
        padding: "0",
        zIndex: "20",
        transition: "opacity 0.1s ease",
        opacity: "0"
    });
    wrapper.appendChild(tooltip);

    // ---------------------------------------------------
    // TOOLTIP HTML BUILDERS
    // ---------------------------------------------------
    //
    // These functions create the content shown when
    // hovering over different types of points (pop estimates or enhancement actions)
    function buildEventTooltipHTML(event) {
        return `
            <div style="border-left:4px solid #999; border-radius:10px; overflow:hidden; width:clamp(260px, 46cqw, 380px);">
                <div style="padding:clamp(8px, 2cqw, 10px) clamp(14px, 4cqw, 18px);">
                    <div style="display:flex; align-items:baseline; gap:10px; margin-bottom:5px;">
                        <span style="font-size:clamp(12px, 3.2cqw, 15px); font-weight:700; color:#045B4C;">${event.year}</span>
                        <span style="font-size:clamp(10px, 2.4cqw, 12px); font-weight:600; color:#999; text-transform:uppercase; letter-spacing:0.4px;">${event.label || "Enhancement Action"}</span>
                    </div>
                    <p style="font-size:clamp(11px, 2.8cqw, 13px); line-height:1.4; color:#444; margin:0;">
                        ${event.description || "No description recorded."}
                    </p>
                </div>
            </div>
        `;
    }

    function buildDensityTooltipHTML(point) {
        return `
            <div style="border-left:4px solid #045B4C; border-radius:10px; overflow:hidden; width:max-content; min-width:clamp(160px, 26cqw, 190px); max-width:clamp(210px, 34cqw, 260px);">
                <div style="padding:clamp(10px, 3cqw, 14px) clamp(11px, 3.3cqw, 16px);">
                    <div style="font-size:clamp(9px, 2.2cqw, 11px); font-weight:600; color:#045B4C; text-transform:uppercase; letter-spacing:0.4px; margin-bottom:4px; white-space:nowrap;">
                        Estimated Density
                    </div>
                    <div style="display:flex; align-items:baseline; gap:8px; white-space:nowrap;">
                        <span style="font-size:clamp(12px, 3.2cqw, 15px); font-weight:700; color:#222;">${point.year}</span>
                        <span style="font-size:clamp(12px, 3.2cqw, 15px); color:#444;">${point.density_estimate.toLocaleString()} oysters per m<sup>2</sup></span>
                    </div>
                    <div style="font-size:clamp(10px, 2.6cqw, 12px); color:#888; margin-top:3px; white-space:nowrap;">
                        ± ${point.std_err.toLocaleString(undefined, { maximumFractionDigits: 1 })} SE
                    </div>
                </div>
            </div>
        `;
    }

    // ---------------------------------------------------
    // ADD HOVER INTERACTION
    // ---------------------------------------------------
    // Find the SVG element created by Observable Plot
    const svgEl = chart.tagName === "svg" ? chart : chart.querySelector("svg");

    // Get the chart's x and y conversion tools...
    // These convert data values (years/populations) into screen positions (pixels)
    const xScale = svgEl.scale ? svgEl.scale("x") : chart.scale("x");
    const yScale = svgEl.scale ? svgEl.scale("y") : chart.scale("y");
    const svgNS = "http://www.w3.org/2000/svg"; // Required for creating SVG elements

    // Function that creates an invisible clickable area over each point
    function addHoverPoint(datum, cx, cy, buildHTML) {
        // Create an invisible circle.
        // The user can hover over this even though the actual chart point is small
        const hitCircle = document.createElementNS(svgNS, "circle");
        hitCircle.setAttribute("cx", cx);
        hitCircle.setAttribute("cy", cy);
        hitCircle.setAttribute("r", 12); // Larger radius makes hovering easier
        hitCircle.setAttribute("fill", "transparent"); // Make invisible
        hitCircle.style.cursor = "pointer";
        svgEl.appendChild(hitCircle);

        // When mouse enters point:
        hitCircle.addEventListener("pointerenter", () => {
            // Fill tooltip with correct information
            tooltip.innerHTML = buildHTML(datum);
            // Show tooltip
            tooltip.style.display = "block";

            // Find point position on screen
            const pointRect = hitCircle.getBoundingClientRect();
            const wrapperRect = wrapper.getBoundingClientRect();
            // Convert position relative to chart container
            const px = pointRect.left + pointRect.width / 2 - wrapperRect.left;
            const py = pointRect.top + pointRect.height / 2 - wrapperRect.top;

            // Decide whether tooltip fits to the right or left
            const tw = tooltip.offsetWidth;
            const th = tooltip.offsetHeight;
            const OFFSET = 3; // How far away from point to start tooltip

            const spaceRight = wrapperRect.width - px;
            const spaceAbove = py;

            let left = spaceRight - OFFSET >= tw ? px + OFFSET : px - tw - OFFSET;
            let top = spaceAbove - OFFSET >= th ? py - th - OFFSET : py + OFFSET;

            // Clamp so the tooltip never spills outside the wrapper's bounds
            left = Math.max(4, Math.min(left, wrapperRect.width - tw - 4));
            top = Math.max(4, Math.min(top, wrapperRect.height - th - 4));

            tooltip.style.left = `${left}px`;
            tooltip.style.top = `${top}px`;
            tooltip.style.opacity = "0.88";
        });

        // Hide tooltip when user leaves point
        hitCircle.addEventListener("pointerleave", () => {
            tooltip.style.opacity = "0";
            tooltip.style.display = "none";
        });
    }
    // Add hover areas for density points
    cleanDens.forEach(p => {
        addHoverPoint(p, xScale.apply(p.year), yScale.apply(p.density_estimate), buildDensityTooltipHTML);
    });

    // Add hover areas for enhancement actions
    eventsWithY.forEach(ev => {
        addHoverPoint(ev, xScale.apply(ev.year), yScale.apply(ev.y2), buildEventTooltipHTML);
    });

    return wrapper;
} // END DENSITY + TIMELINE COMBINED PLOT


// ===================================================
// ===================================================
// SHARED FUNCTION: SHELL HEIGHT HISTOGRAM
// Same chart for all sites that have size data
// Pass in an array of shell height measurments 
// ===================================================
// ===================================================
function createShellHeightHistogram(sizeData) {
    if (!sizeData || sizeData.length === 0) {
        // If there is no size data, return nothing
        return null;
    }

    return Plot.plot({
        height: 280,
        marginLeft: 50,
        marginRight: 20,
        marginTop: 20,
        marginBottom: 50,
        insetTop: 15,

        x: {
          label: "Shell height (mm)",
          nice: true  
        },
        y: {
          label: "Count",
          grid: true  
        },
        marks: [
            Plot.rectY(
                sizeData,
                Plot.binX(
                    { y: "count" },
                    {
                        x: "height_mm",
                        fill: "#045B4C",
                        fillOpacity: 0.8,
                        thresholds: 20
                    }
                )
            ),
            Plot.ruleY([0]),

            // Add in interactivity
            // Tooltip will tell you the range of sizes in each bin, and the count in that range
            Plot.tip(sizeData, Plot.pointerX(Plot.binX(
            { y: "count" },
            {
                x: "height_mm",
                thresholds: 20
            }
        )))
        ],
        style: {
            fontFamily: "inherit",
            fontSize: "14px"
        }
    });
} // END SHELL HEIGHT HISTOGRAM BUILDER FUNCTION

// ===================================================
// ===================================================
// SHARED FUNCTION: MAP TOOLTIP CONTENT BUILDER
// Builds HTML string for enhancement marker tooltip.
// 3 cases:
//      1. Story site: includes 'click to explore' banner
//      2. Non-story site: no banner
//      3. No timeline data: photo only + note
// ===================================================
// ===================================================
function buildTooltipHTML(site, timelineData, isStorySite, photoUrl) {

    // --- PHOTO BLOCK ---
    // Full width image at top of tooltip
    // If no photo exists, render nothing
    const photoHTML = photoUrl ? `
        <img src="${photoUrl}" style="
            width: 100%; height: 130px; object-fit: cover;
            display: block;">
    ` : "";

    // --- Meta Rows ---
    // Total acres
    // Grab only rows for this site
    const siteRows = timelineData
        .filter(d => d.site === site.site_name && d.year)  // skip rows with no year
        .sort((a, b) => a.year - b.year);                  // sort oldest to newest
        
    // Add up acres column from timeline data
    const totalAcres = siteRows.reduce((sum, d) => {
        const val = parseFloat(d.acres);
        return sum + (isNaN(val) ? 0 : val);
    }, 0);

    // Only show total acres line if there is a value, else -
    const acresDisplay = totalAcres > 0
        ? `${totalAcres.toFixed(2)} acres enhanced`
        : "—"; 

    // Enhancement types
    const typeDisplay = site.enhancement_actions
        ? site.enhancement_actions.split(',').map(t => t.trim()).join(' · ')
        : "—";
    
    // HTML styling for these rows
    const metaHTML = `
    <div style="display:flex; align-items:center; gap:6px;
        font-size:12px; color:#555; margin-bottom:4px;">
        <span style="color:#045B4C; font-weight:600; font-size:11px; 
            text-transform:uppercase; letter-spacing:0.4px; flex-shrink:0;">Area</span>
        ${acresDisplay}
    </div>
    <div style="display:flex; align-items:center; gap:6px;
        font-size:12px; color:#555; margin-bottom:4px;">
        <span style="color:#045B4C; font-weight:600; font-size:11px;
            text-transform:uppercase; letter-spacing:0.4px; flex-shrink:0;">Type</span>
        ${typeDisplay}
    </div>
    `;

    // --- Timeline rows ---
    // Story sites: show up to 4 rows, then a "more on site page" hint to click
    // Non-story sites: show all rows bc tooltip is the full story
    // No timeline info at all: No data note
    let timelineHTML = "";

    if (siteRows.length === 0) {
        // Fallback for no timeline data recorded for this site
        timelineHTML = `
            <p style="font-size:12px; color:#999; font-style:italic; margin:0;">
                No timeline data recorded
            </p>
        `;
    } else {
        // Cap at 4 rows for story sites, show all for non-story
        const visibleRows = isStorySite ? siteRows.slice(0, 4) : siteRows;
        const hiddenCount = siteRows.length - visibleRows.length;

        // Build one row per visible timeline entry
        const rowsHTML = visibleRows.map(d => `
            <div style="display:flex; align-items:baseline; gap:8px;
                font-size:12px; margin-bottom:5px;">
                <span style="color:#045B4C; font-weight:600;
                    min-width:34px; flex-shrink:0;">${d.year}</span>
                <span style="color:#ccc; font-size:10px; flex-shrink:0;">●</span>
                <span style="line-height:1.4; color:#444;">${d.label}</span>
            </div>
        `).join('');

        // "More actions" nudge when rows were cut for story site
        const moreHint = hiddenCount > 0 ? `
            <p style="font-size:11px; color:#999; font-style:italic; margin:4px 0 0 0;">
                + ${hiddenCount} more action${hiddenCount > 1 ? 's' : ''} on site page
            </p>
        ` : "";

        timelineHTML = `
            <p style="font-size:11px; font-weight:600; color:#045B4C;
                text-transform:uppercase; letter-spacing:0.5px; margin:0 0 7px 0;">
                Enhancement history
            </p>
            ${rowsHTML}
            ${moreHint}
        `;
    }

    // --- Explore banner ---
    // Only for story sites, telling user they can click
    const exploreBanner = isStorySite ? `
        <div style="margin-top:10px; padding:7px 10px;
            background:#FCE8D6; border-radius:6px;
            font-size:10px; font-weight:700; color:#8A4B1F; text-align:center;">
             - Click icon to explore restoration story - 
        </div>
    ` : "";

    // --- Assemble full tooltip ---
    return `
        <div style="min-width:240px; max-width:260px;">
            ${photoHTML}
            <div style="padding:12px;">
                <p style="font-size:15px; font-weight:600; color:#222;
                    text-align:center; margin:0 0 10px 0;">
                    ${site.site_name}
                     ${exploreBanner}
                </p>
                ${metaHTML}
                <div style="height:1px; background:#e8e8e8; margin:8px 0;"></div>
                ${timelineHTML}
            </div>
        </div>
    `;
} // END TOOLTIP CONTENT BUILDER FUNCTION

// ===================================================
// ===================================================
// SITE PANEL BUILDER 
//
// TO ADD A NEW STORY SITE:
//   1. Add its name to story_sites set at the top
//   2. Add a case here pointing to a new "builder" function
//   3. Write the builder function below as we want the site panel to look
// ===================================================
// ===================================================
function buildSitePanel(siteName) {
  switch (siteName) {
    case "Fidalgo Bay":  return buildFidalgoBayPanel();
    case "Oyster Bay":  return buildOysterBayPanel();
    case "Chico Bay":    return buildChicoBayPanel();
    // case "Silverdale":   return buildSilverdalePanel();
  }
} // END BUILD SITE PANEL FUNCTION

// ===================================================
// ===================================================
//
// SITE PANEL: FIDALGO BAY
// Full story & data! Layout:
//   Title --> Carousel --> Intro quote block --> 
//   About This Site --> Our Work --> Timeline --> 
//   Results callout --> Population density plot --> 
//   Impact text --> Shell height histogram --> 
//   Looking Ahead --> Credits, Partners, Funders
//
// ===================================================
// ===================================================
function buildFidalgoBayPanel() {
    const panel = document.createElement("div");

    // --- Narrative ---
    const narrative = {
        intro: `White clouds rise from grey smokestacks, blurring a sprawling refinery into the distant silhouette of Mount Baker. A retired railroad trestle cuts across the bay like an old scar. Human ambition is written plainly on the shoreline, and yet, millions of Olympia oysters tell a remarkable success story.`,

        context: `The story of Fidalgo Bay begins with a rumor: that Olympia oysters once resided in these shallow waters. By the early 2000s, none remained, but the bay’s protected shorelines and limited predators made it an ideal candidate for restoration. In 2002, alongside a strong network of partners, we spread Pacific oyster shell covered in Olympia oyster seed beside the old trestle on the eastern shore, marking the first Olympia oyster restoration effort in northern Puget Sound.`,

        ourWork: `What followed was a years-long conversation with the bay. Additional seeded cultch were added in subsequent years. Non-seed bearing Pacific oyster shell was introduced in 2006, 2008, and 2013 to enhance the substrate and expand the area available for larval settlement. When monitoring revealed that nearly all natural recruitment was concentrated on the eastern side, likely shaped by summer current patterns, we responded by seeding the west side of the bay in 2016. In 2018, two new half-acre plots of bulk Pacific shell were added, one on each side of the bay, and the west side was seeded once more months later to give larval abundance a fresh boost.`,

        dataCallout: `Since 2002, the estimated Olympia oyster population in Fidalgo Bay has grown from roughly 25,000 to over 5.5 million - a more than hundredfold increase over two decades.`,

        impact: `Growth through the 2000s and early 2010s was steady, from the initial 25,000 seeded individuals to 240,000 by 2013. Then, something shifted. The population began to accelerate, explosive growth driven no longer by our additions, but by the Olys themselves! The last 5 years alone saw numbers nearly double, from 2.9 million in 2018 to 5.5 million in 2023.`,

        sizeContext: `While most of these individuals remain within the enhanced shell plots, the Olys are expanding into areas where we wouldn’t have expected them. In 2023, we counted over 1.2 million oysters in the marsh channels at the far southern end of the bay, well beyond the reach of any direct seeding effort. This was not only the densest aggregation observed that year, but also home to some of the largest individual Olympia oysters recorded anywhere in Puget Sound, with some measuring over 70mm.`,

        future: `Fidalgo Bay is not oly a local success story, but also the starting point for Olympia oyster restoration across the region. Adult oysters from here have been raised as hatchery broodstock, transplanted directly to new sites, and (in a particularly elegant turn) the bay itself has functioned as a natural hatchery, with post-larvae captured on Pacific oyster cultch bags transferred to other bays. Restoration efforts in Sequim Bay, Fisherman Bay on Lopez Island, Skagit and Similk Bays, Padilla Bay, Samish Bay, Chuckanut Bay, and Drayton Harbor have all been seeded by what grew here. Since 2002, approximately 3,000 bags of spat-on-shell from Fidalgo Bay broodstock have gone out to support restoration across the north Sound.`,

        partnersLead: `The story of Fidalgo Bay is, at its heart, a story showcasing the power of reiterative enhancement actions and strong community partnerships. Walk these tidelands today and you’ll find something quite extraordinary. This would not have been possible without the extensive efforts of this incredible network of partners and community members.`,

        partnersList: `Taylor Shellfish, WDFW, Skagit County Marine Resources Committee (MRC), Swinomish Indian Tribal Community, Samish Indian Nation, Northwest Straits Foundation, Rose Foundation, City of Anacortes, and many others.`
    };

    // --- Layout HTML ---
    // Some of these are placeholder divs for dynamic content like plots
    panel.innerHTML =  `
        <!-- Site title 
        <h2 style="
        font-size: 32px; font-weight: 700; color: #045B4C;
        text-align: center; margin: 0 0 24px 0;
        letter-spacing: 0.5px; line-height: 1.2;
        ">Fidalgo Bay</h2> -->

        <!-- Carousel placeholder -->
        <div id="fidalgo-carousel"></div>

        <!-- Intro quote -->
        <div style="
        font-size: 16px; line-height: 1.8; color: #333;
        margin-bottom: 32px; padding: 24px;
        background: linear-gradient(to right, #f0f7f6, transparent);
        border-left: 4px solid #045B4C; font-style: italic;
        ">${narrative.intro}</div>

        <!-- About This Site -->
        <div style="margin-bottom: 40px;">
        <h3 style="
            font-size: 18px; font-weight: 700; color: #045B4C;
            margin: 0 0 16px 0; text-transform: uppercase; letter-spacing: 0.5px;
        ">About</h3>
        <p style="font-size: 15px; line-height: 1.8; color: #444; margin: 0;">
            ${narrative.context}
        </p>
        </div>

        <!-- Our Work -->
        <div style="
        background: #f8f9fa; padding: 24px; border-radius: 8px; margin-bottom: 40px;
        ">
        <h3 style="
            font-size: 18px; font-weight: 700; color: #045B4C;
            margin: 0 0 16px 0; text-transform: uppercase; letter-spacing: 0.5px;
        ">Our Work</h3>
        <p style="font-size: 15px; line-height: 1.8; color: #444; margin: 0;">
            ${narrative.ourWork}
        </p>
        </div>

        <!-- Population growth + enhancement timeline, combined -->
        <div style="
        background: white; padding: 24px; border-radius: 8px;
        box-shadow: 0 2px 8px rgba(0,0,0,0.08); margin-bottom: 40px;
        ">
        <h3 style="
            font-size: 16px; font-weight: 700; color: #045B4C;
            margin: 0 0 8px 0; text-transform: uppercase; letter-spacing: 0.5px;
        ">Population Growth &amp; Restoration Timeline</h3>
        <p style="font-size: 14px; color: #666; margin: 0 0 12px 0; font-style: italic;">
            Estimated population size at Fidalgo Bay, 2001 to 2023
        </p>
        <div id="fidalgo-population-plot"></div>
        <div style="display:flex; align-items:center; gap:8px; margin-top:12px; font-size:12px; color:#888;">
            <span style="display:inline-block; width:18px; height:0; border-top:2px dashed #999;"></span>
            Enhancement action — hover the line for details
        </div>
        </div>

        <!-- Data callout -->
        <div style="
        padding: 20px;
        background: linear-gradient(135deg, #e8f4f2 0%, #f0f7f6 100%);
        border-radius: 8px; border-left: 4px solid #045B4C; margin-bottom: 24px;
        ">
        <p style="font-size: 15px; line-height: 1.7; color: #333; margin: 0; font-weight: 500;">
            ${narrative.dataCallout}
        </p>
        </div>

        <!-- Impact text -->
        <div style="margin-bottom: 40px;">
        <p style="font-size: 15px; line-height: 1.8; color: #444; margin: 0;">
            ${narrative.impact}
        </p>
        </div>

        <!-- Shell height section -->
        <div style="
        background: white; padding: 24px; border-radius: 8px;
        box-shadow: 0 2px 8px rgba(0,0,0,0.08); margin-bottom: 24px;
        ">
        <h3 style="
            font-size: 16px; font-weight: 700; color: #045B4C;
            margin: 0 0 8px 0; text-transform: uppercase; letter-spacing: 0.5px;
        ">Oyster Size Class Distribution</h3>
        <p style="font-size: 14px; color: #666; margin: 0 0 20px 0; font-style: italic;">
            Most recent distribution of individual oyster shell heights, measured 2023
        </p>
        <div id="fidalgo-size-plot"></div>
        </div>

        <!-- Size context text -->
        <div style="margin-bottom: 40px;">
        <p style="font-size: 15px; line-height: 1.8; color: #444; margin: 0;">
            ${narrative.sizeContext}
        </p>
        </div>

        <!-- Looking Ahead -->
        <div style="
        background: linear-gradient(135deg, #f0f7f6 0%, #e8f4f2 100%);
        padding: 28px; border-radius: 8px;
        border-left: 4px solid #045B4C; margin-bottom: 40px;
        ">
        <h3 style="
            font-size: 18px; font-weight: 700; color: #045B4C;
            margin: 0 0 16px 0; text-transform: uppercase; letter-spacing: 0.5px;
        ">Looking Ahead</h3>
        <p style="font-size: 15px; line-height: 1.8; color: #444; margin: 0;">
            ${narrative.future}
        </p>
        </div>

        <!-- Partners -->
        <div style="
            border-top: 1px solid #e0e0e0;
            padding-top: 32px;
            margin-bottom: 40px;
        ">
            <h3 style="
                font-size: 14px; font-weight: 700; color: #045B4C;
                margin: 0 0 12px 0; text-transform: uppercase; letter-spacing: 0.5px;
            ">A Huge Thank You</h3>
            <p style="font-size: 15px; line-height: 1.8; color: #444; margin: 0 0 12px 0;">
                ${narrative.partnersLead}
            </p>
            <p style="font-size: 14px; line-height: 1.8; color: #666; margin: 0;">
                ${narrative.partnersList}
            </p>
        </div>
    `;

    // Insert dyanmic content (plots!!) into placeholder divs built above

    // Photos for the carousel
    const photos = [
        tooltipPhotos["Fidalgo Bay"], // First photo is the tooltip photos
        FileAttachment("data/images/happy_elsa.jpg").href,
        FileAttachment("data/images/fidalgo_2002_betsy_billtaylor.JPG").href,
        FileAttachment("data/images/fidalgo_2003_trestle_bags.jpg").href,
        FileAttachment("data/images/fidalgo_2006_paulbetsy.jpg").href,
        FileAttachment("data/images/fidalgo_2013_shell_barge.JPG").href,
        FileAttachment("data/images/fidalgo_pretty_olys_closeup.JPG").href,
    ].filter(Boolean);

    const captions = [
        "View of Mount Baker from Fidalgo Bay",
        "A happy Elsa with a shell bag",
        "PSRF founder Besty and Bill Taylor prepping to place shell, 2002",
        "Placing shell bags near the trestle, 2003",
        "Betsy and Paul placing shell, 2006",
        "Loads of shell for the 2013 bulk shell enhancement",
        "Beautiful Olys!",
    ];

    buildCarousel(panel.querySelector("#fidalgo-carousel"), photos, captions);

    // Timeline
    // Combined population growth + enhancement timeline plot
    panel.querySelector("#fidalgo-population-plot")
        .appendChild(createPopulationTimelinePlot(fidalgo_pop_est, timeline_data, "Fidalgo Bay"));

    // Shell height histogram
    // Not yet 100% sure what this will look like, but this is one idea
    // const fidalgoSizeData = fidalgo_heights; // Data will go in here when we have it!! 
    // example for above: 
    // [ann_densities.filter(d => d.location === "Fidalgo Bay" && d.shell_height_mm)]
    panel.querySelector("#fidalgo-size-plot")
        .appendChild(createShellHeightHistogram(fidalgo_heights));

    return panel;
} // END BUILD FIDALGO BAY PANEL


// ===================================================
// ===================================================
//
// SITE PANEL: OYSTER BAY
// Layout:
//
// ===================================================
// ===================================================
function buildOysterBayPanel() {
    const panel = document.createElement("div");

    // --- Narrative ---
    const narrative = {
        intro: `In 2010, the discovery of one of the most prolific Olympia oyster beds the team had yet encountered, sitting near the mouth of Dyes Inlet in Mud Bay, offered a vivid demonstration of what this inlet could hold. Naturally, the team was anxious to know what else might be tucked away in its farther reaches. Just around the point was a place with a promising name: Oyster Bay.`,

        context: `The first visit was a strikeout. Within the tidal heights where Olys typically thrive, none were to be found. The team continued deeper into Dyes Inlet with little luck finding a bed nearly as dense as what Mud had to offer. But, PSRF’s Brian Allen couldn’t shake the hunch that they were missing something. On a whim, at a much lower tide than before, he made a return visit. There, in the center of Oyster Bay, uncovered by the receding water, was a small peninsula absolutely covered in Olympia oysters.`,

        ourWork: `In 2011, the team placed a half-acre plot of bulk Pacific oyster shell adjacent to this small but dense natural aggregation, hoping to expand available habitat and coax the population higher into the intertidal. It was one of our earliest uses of bulk shell as a restoration tool, and Oyster Bay became a place to pay close attention, and a site that would prove formative to our learning.`,

        dataCallout: `Results came quicker than expected. That following spring, the added shell was absolutely loaded with juvenile oysters, a striking early expansion that suggested something special about this bay.`, 
        
        results: `Low exposure, calm water, no major terrestrial inputs, and the kind of hydrodynamics favorable for larval retention made Oyster Bay an exceptional environment for these animals. The Olys here, as the team would come to learn, tend to dance to their own beat, recruiting strongly in years when settlement elsewhere in the Sound lays low.`,

        impact: `For the next several years, Brian returned regularly to keep an eye on things. Then, in 2020, the team returned and what they found was unexpected: the shell placed in 2011 had largely been buried into the sediment. But the oysters, they had gone everywhere. From the deep zone where they’d originally lived, the population had spread across the beach, climbing all the way up to the +1 foot elevation and filling the full normal intertidal range of the species, down to the -2 feet and perhaps even deeper. And this wasn’t a scattered population, but rather dense, semi-structured aggregations boasting more than 100 Olys per square meter in many places.`,

        restorationQuestion: `The question the team carried home was one that follows many restoration projects: did the 2011 project kick this off, or did the team act at precisely the right moment, just as a broader upswing in natural reproduction was already underway?`,

        sizeIntro: `Oyster Bay also became a classroom. In the early years of working here, the team collected some of their first systematic data on Oly size distributions within a population, data that went on to reveal a meaningful pattern. `,

        sizeContext: `Young, developing beds show a size distribution skewed toward smaller individuals, a pronounced mode associated with young-of-year recruits. Mature, established beds look more normally distributed across size classes. This insight, developed in part by careful observation at Oyster Bay, gave the team a new lens for reading the health and trajectory of populations across the Sound.`,
        
        habitatDescription: `Since the first population survey in 2011 estimated roughly 400,000 individuals in the natural aggregation, the population has doubled to over 800,000 as of 2026. But population estimates, by their nature, capture only what can be counted within a defined survey area at a fixed point in time. Walk the beach at Oyster Bay today and the numbers feel like an understatement. Olys sprawl across the substrate in dense, layered masses, spilling into areas well beyond any of our formal survey boundaries. The habitat is absolutely incredible, showing what a restored Olympia oyster bed, fully realized, looks like.`,

        closing: `Oyster Bay remains an active monitoring site, tracked through both population surveys and recruitment monitoring. The team isn’t the only ones keeping a close eye on things - a resident population of Canada geese has claimed a small island in the bay as their own, and they take their oversight role seriously (sometimes, a little too seriously). After 15 years, it has become one of the richest Olympia oyster habitats in Dyes Inlet, a quiet bay that has, by any measure, earned its name. `
    };

    // --- Layout HTML ---
    // Some of these are placeholder divs for dynamic content like plots
    panel.innerHTML =  `
        <!-- Site title 
        <h2 style="
        font-size: 32px; font-weight: 700; color: #045B4C;
        text-align: center; margin: 0 0 24px 0;
        letter-spacing: 0.5px; line-height: 1.2;
        ">Oyster Bay</h2> -->

        <!-- Carousel placeholder -->
        <div id="oysterbay-carousel"></div> 

        <!-- Intro quote -->
        <div style="
        font-size: 16px; line-height: 1.8; color: #333;
        margin-bottom: 32px; padding: 24px;
        background: linear-gradient(to right, #f0f7f6, transparent);
        border-left: 4px solid #045B4C; font-style: italic;
        ">${narrative.intro}</div>
 
        <!-- About -->
        <div style="margin-bottom: 40px;">
        <h3 style="
            font-size: 18px; font-weight: 700; color: #045B4C;
            margin: 0 0 16px 0; text-transform: uppercase; letter-spacing: 0.5px;
        ">About</h3>
        <p style="font-size: 15px; line-height: 1.8; color: #444; margin: 0;">
            ${narrative.context}
        </p>
        </div>
 
        <!-- Our Work -->
        <div style="
        background: #f8f9fa; padding: 24px; border-radius: 8px; margin-bottom: 40px;
        ">
        <h3 style="
            font-size: 18px; font-weight: 700; color: #045B4C;
            margin: 0 0 16px 0; text-transform: uppercase; letter-spacing: 0.5px;
        ">Our Work</h3>
        <p style="font-size: 15px; line-height: 1.8; color: #444; margin: 0;">
            ${narrative.ourWork}
        </p>
        </div>
 
        <!-- Callout -->
        <div style="
        padding: 20px;
        background: linear-gradient(135deg, #e8f4f2 0%, #f0f7f6 100%);
        border-radius: 8px; border-left: 4px solid #045B4C; margin-bottom: 24px;
        ">
        <p style="font-size: 15px; line-height: 1.7; color: #333; margin: 0; font-weight: 500;">
            ${narrative.dataCallout}
        </p>
        </div>
 
        <!-- Rest of early results, plain prose -->
        <div style="margin-bottom: 40px;">
        <p style="font-size: 15px; line-height: 1.8; color: #444; margin: 0;">
            ${narrative.results}
        </p>
        </div>
 
        <!-- Impact text -->
        <div style="margin-bottom: 40px;">
        <p style="font-size: 15px; line-height: 1.8; color: #444; margin: 0;">
            ${narrative.impact}
        </p>
        </div>
 
        <!-- Population plot -->
        <div style="
        background: white; padding: 24px; border-radius: 8px;
        box-shadow: 0 2px 8px rgba(0,0,0,0.08); margin-bottom: 24px;
        ">
        <h3 style="
            font-size: 16px; font-weight: 700; color: #045B4C;
            margin: 0 0 8px 0; text-transform: uppercase; letter-spacing: 0.5px;
        ">Population Size Over Time</h3>
        <p style="font-size: 14px; color: #666; margin: 0 0 20px 0; font-style: italic;">
            Estimated population size at Oyster Bay, 2011 to 2026
        </p>
        <div id="oysterbay-population-plot"></div>
        </div>
 
        <!-- Restoration question -->
         <div style="
        background: #f8f9fa; padding: 24px; border-radius: 8px; margin-bottom: 24px;
        ">
        <p style="font-size: 15px; line-height: 1.8; color: #444; margin: 0;">
            ${narrative.restorationQuestion}
        </p>
        </div>
 
        <!-- Reading the Population -->
        <div style="margin-bottom: 40px;">
        <h3 style="
            font-size: 18px; font-weight: 700; color: #045B4C;
            margin: 0 0 16px 0; text-transform: uppercase; letter-spacing: 0.5px;
        ">Reading the Population</h3>
        <p style="font-size: 15px; line-height: 1.8; color: #444; margin: 0;">
            ${narrative.sizeIntro}
        </p>
        </div>
 
        <!-- Size class distribution chart -->
        <div style="
        background: white; padding: 24px; border-radius: 8px;
        box-shadow: 0 2px 8px rgba(0,0,0,0.08); margin-bottom: 24px;
        ">
        <h3 style="
            font-size: 16px; font-weight: 700; color: #045B4C;
            margin: 0 0 8px 0; text-transform: uppercase; letter-spacing: 0.5px;
        ">Oyster Size Class Distribution</h3>
        <p style="font-size: 14px; color: #666; margin: 0 0 20px 0; font-style: italic;">
            Most recent distribution of individual oyster shell heights, measured 2026
        </p>
        <div id="oysterbay-size-plot"></div>
        </div>
 
        <!-- Size context -->
        <div style="margin-bottom: 40px;">
        <p style="font-size: 15px; line-height: 1.8; color: #444; margin: 0;">
            ${narrative.sizeContext}
        </p>
        </div>
 
        <!-- The Bed Today -->
         <div style="
        background: #f8f9fa; padding: 24px; border-radius: 8px; margin-bottom: 24px;
        ">
        <h3 style="
            font-size: 18px; font-weight: 700; color: #045B4C;
            margin: 0 0 16px 0; text-transform: uppercase; letter-spacing: 0.5px;
        ">The Bed Today</h3>
        <p style="font-size: 15px; line-height: 1.8; color: #444; margin: 0;">
            ${narrative.habitatDescription}
        </p>
        </div>
 
        <!-- Still Watching -->
        <div style="margin-bottom: 40px;">
            <h3 style="
                font-size: 18px; font-weight: 700; color: #045B4C;
                margin: 0 0 16px 0; text-transform: uppercase; letter-spacing: 0.5px;
            ">Still Watching</h3>
            <p style="font-size: 15px; line-height: 1.8; color: #444; margin: 0;">
                ${narrative.closing}
            </p>
        </div>
    `;

    // Insert dyanmic content (plots!!) into placeholder divs built above

    // Photos for the carousel
    const photos = [
        tooltipPhotos["Oyster Bay"], // First photo is the tooltip photos
        // Add more photos in like this once we have them:
        // FileAttachment("data/images/fidalgo_2.jpg").href, 
        // etc,
        // etc
        FileAttachment("data/images/oysterbay_enhancement.jpg").href,
        FileAttachment("data/images/oysterbay_2012.JPG").href,
        FileAttachment("data/images/oysterbay_survey_2026.jpg").href,
        FileAttachment("data/images/oysterbay_loads_of_olys_2026.png").href
    ].filter(Boolean);

    const captions = [
        "Close up of a diverse Oly habitat",
        "Spraying bulk shell into the water at high tide",
        "View of the enhancement plot creating structured substrate at low tide",
        "Sofia counting Olys",
        "Piles of oysters!"
    ];

    buildCarousel(panel.querySelector("#oysterbay-carousel"), photos, captions);

        
    // Population plot
    panel.querySelector("#oysterbay-population-plot")
       .appendChild(createPopulationTimelinePlot(oysterbay_pop_est, timeline_data, "Oyster Bay"));
    
    // Shell heights plot
    panel.querySelector("#oysterbay-size-plot")
       .appendChild(createShellHeightHistogram(oysterbay_heights));

    return panel;
} // END BUILD OYSTER BAY PANEL

// ===================================================
// ===================================================
//
// SITE PANEL: CHICO BAY
// Layout:
//   Title --> Carousel --> Intro quote block -->
//   About This Site --> Our Work --> 2018 By The Numbers callout -->
//   Debate text --> Density plot placeholder --> Early results stat grid -->
//   Density-by-zone stat grid --> Size class callout -->
//   Looking Ahead --> Shell height plot placeholder --> Credits, Partners
//
// ===================================================
// ===================================================
function buildChicoBayPanel() {
    const panel = document.createElement("div");

    // --- Narrative ---
    const narrative = {
        intro: `A traditional shellfish harvesting area with historic importance, Chico Bay sits at the mouth of Chico Creek, one of the most productive chum streams in the Sound. Since purchase in the late 2000s, the Suquamish Tribe has been seeding the tidelands with clams and oysters, alongside harvesting a booming wild manila clam population around the corner near Erlands Point. Also at Erlands Point, a small, wild aggregation of Olympia oysters sparked inspiration for what Chico Bay could be.`,

        context: `With USDA conservation funding in hand and permission to work on a stretch of Tribally owned tideland, the team moved cautiously, staking out a series of 10-by-10 foot shell plots across the tideland to first test whether that inspiration could take hold on a larger scale. Before committing to a project design, we let those plots simmer for nearly a year, and results upon our return pointed us clearly downhill. High in the intertidal the shell plots sat mostly empty, but lower, near -1.5 feet MLLW, recruitment showed promise. Then, a closer look at the deepest reaches of the flat, around -3 feet, turned up something else: a scatter of old, solitary Olys, likely survivors of rare and irregular recruitment events rather than a self-sustaining population. Guided by these findings, the project footprint shifted down the beach from the initially anticipated plot, toward elevations where the bay was calling us to work.`,

        ourWork: `In 2018, we put that plan into action. We spread 5 acres of Pacific oyster shell to provide settlement substrate for recruiting juveniles, paired with more that 1.15 million hatchery-reared baby Olys set on 450 bags of Pacific shell placed directly into the enhancement area. The stock enhancement piece was not without internal debate. With a wild population already present nearby, was a hatchery-grown boost really necessary, or should the shell alone have been enough to do the job? The project moved forward with both tools in hand, a bet on giving the bay every possible advantage.`,

        earlyResultsIntro: `We checked back that following year, and by August 2019, the enhancement area was averaging 130 Olys per square meter across 40 samples, an encouraging early sign that the project was off to a good start. By April 2021, that average had settled to 80.8 Olys per square meter across 19 samples, though the variability between samples in both years was wide. That same 2021 survey mapped 3.7 acres of shell still visibility available for settlement, and oyster density near the seeded cultch specifically reached 367.7 Olys per square meter, compared to just 4.3 oysters per square meter in the outer enhancement area.`,

        sizeClasses: `Also in 2021, Olys of multiple size classes were present, ranging from 35mm-55mm individuals (likely tracing back to the original 2018 cohort or 2019 natural set), down to 15mm oysters representing a newer wave of settlement from 2020, a sign that the population was not just surviving, but reproducing on its own.`,

        future: `Chico Bay’s smoldering Oly population is still early in its story. The 2021 numbers capture a single snapshot of a population that’s only three years past planting, on tideland with a much longer memory than that. What comes next is still being written, and it’s worth going back to read.`,

        partnersList: `This project was made possible through generous support from USDA, the National Fish & Wildlife Foundation, the Burning Foundation, and the Washington Women’s Foundation, in partnership with the Suquamish Tribe.`
    };

    // --- Layout HTML ---
    panel.innerHTML =  `
        <!-- Carousel -->
        <div id="chico-carousel"></div>

        <!-- Intro quote -->
        <div style="
        font-size: 16px; line-height: 1.8; color: #333;
        margin-bottom: 32px; padding: 24px;
        background: linear-gradient(to right, #f0f7f6, transparent);
        border-left: 4px solid #045B4C; font-style: italic;
        ">${narrative.intro}</div>

        <!-- About This Site -->
        <div style="margin-bottom: 40px;">
        <h3 style="
            font-size: 18px; font-weight: 700; color: #045B4C;
            margin: 0 0 16px 0; text-transform: uppercase; letter-spacing: 0.5px;
        ">About</h3>
        <p style="font-size: 15px; line-height: 1.8; color: #444; margin: 0;">
            ${narrative.context}
        </p>
        </div>

        <!-- Our Work -->
        <div style="
        background: #f8f9fa; padding: 24px; border-radius: 8px; margin-bottom: 24px;
        ">
        <h3 style="
            font-size: 18px; font-weight: 700; color: #045B4C;
            margin: 0 0 16px 0; text-transform: uppercase; letter-spacing: 0.5px;
        ">Our Work</h3>
        <p style="font-size: 15px; line-height: 1.8; color: #444; margin: 0;">
            ${narrative.ourWork}
        </p>
        </div>

        <!-- Density plot placeholder -->
        <div style="
        background: white; padding: 24px; border-radius: 8px;
        box-shadow: 0 2px 8px rgba(0,0,0,0.08); margin-bottom: 40px;
        ">
        <h3 style="
            font-size: 16px; font-weight: 700; color: #045B4C;
            margin: 0 0 8px 0; text-transform: uppercase; letter-spacing: 0.5px;
        ">Oyster Density Over Time</h3>
        <p style="font-size: 14px; color: #666; margin: 0 0 12px 0; font-style: italic;">
            Average Olympia oysters per square meter, Chico Bay enhancement area
        </p>
        <div id="chico-density-plot"></div>
        </div>

        <!-- Results -->
        <div style="margin-bottom: 24px;">
        <h3 style="
            font-size: 18px; font-weight: 700; color: #045B4C;
            margin: 0 0 16px 0; text-transform: uppercase; letter-spacing: 0.5px;
        ">Early Progress</h3>
        <p style="font-size: 15px; line-height: 1.8; color: #444; margin: 0 0 16px 0;">
            ${narrative.earlyResultsIntro}
        </p>
        </div>


        <!-- Size class callout -->
        <div style="
        padding: 20px;
        background: linear-gradient(135deg, #f0f7f6 0%, #e8f4f2 100%);
        border-radius: 8px; border-left: 4px solid #045B4C; margin-bottom: 40px;
        ">
        <p style="font-size: 15px; line-height: 1.7; color: #333; margin: 0;">
            ${narrative.sizeClasses}
        </p>
        </div>

        <!-- Shell height plot -->
        <div style="
        background: white; padding: 24px; border-radius: 8px;
        box-shadow: 0 2px 8px rgba(0,0,0,0.08); margin-bottom: 40px;
        ">
        <h3 style="
            font-size: 16px; font-weight: 700; color: #045B4C;
            margin: 0 0 8px 0; text-transform: uppercase; letter-spacing: 0.5px;
        ">Oyster Size Class Distribution</h3>
        <p style="font-size: 14px; color: #666; margin: 0 0 20px 0; font-style: italic;">
            Distribution of individual oyster shell heights, measured 2021
        </p>
        <div id="chico-size-plot"></div>
        </div>

        <!-- Looking Ahead -->
        <div style="margin-bottom: 40px;">
        <h3 style="
            font-size: 18px; font-weight: 700; color: #045B4C;
            margin: 0 0 16px 0; text-transform: uppercase; letter-spacing: 0.5px;
        ">Looking Ahead</h3>
        <p style="font-size: 15px; line-height: 1.8; color: #444; margin: 0;">
            ${narrative.future}
        </p>
        </div>

        <!-- Partners -->
        <div style="
            border-top: 1px solid #e0e0e0;
            padding-top: 32px;
            margin-bottom: 40px;
        ">
            <h3 style="
                font-size: 14px; font-weight: 700; color: #045B4C;
                margin: 0 0 12px 0; text-transform: uppercase; letter-spacing: 0.5px;
            ">A Huge Thank You</h3>
            <p style="font-size: 14px; line-height: 1.8; color: #666; margin: 0;">
                ${narrative.partnersList}
            </p>
        </div>
    `;

    // Insert dynamic content into placeholder divs built above

    // Photos for the carousel
    const photos = [
        tooltipPhotos["Chico Bay"], // First photo is the tooltip photo
        // Add more photos in like this once we have them:
        // FileAttachment("data/images/chicobay_2.jpg").href,
        FileAttachment("data/images/chico_survey.jpg").href,
        FileAttachment("data/images/chico_oly_closeup.jpg").href,
        FileAttachment("data/images/chico_landscape.jpg").href,
    ].filter(Boolean);

    const captions = [
            "Heading out to survey the enhancement",
            "Counting Olys",
            "Close up of an Oly cluster",
            "Bulk shell creating firm, structured substrate",
        ];

    buildCarousel(panel.querySelector("#chico-carousel"), photos, captions);

    // Plots
      panel.querySelector("#chico-density-plot")
          .appendChild(createDensityTimelinePlot(chicobay_dens_est, timeline_data, "Chico Bay"));
      panel.querySelector("#chico-size-plot")
          .appendChild(createShellHeightHistogram(chicobay_heights));

    return panel;
} // END BUILD CHICO BAY PANEL


// ===================================================
// ===================================================
// YEAR SLIDER BUILDER (RECRUITMENT TAB)
//
// Creates an <input type="range"> slider for the
// recruitment tab. Could have done this using a pre-built 
// slider input, but it was harder to make it pretty that way
//
// Arguments:
//   years - Unique years in the data (array)
//   currentYear - the currently selected year
//   onChange    - callback fn(year) called on slide
// ===================================================
// ===================================================
function buildYearSlider(years, currentYear, onChange) {

    // Outer div for label + slider + year display
    const wrapper = document.createElement("div");
    // Style it
    Object.assign(wrapper.style, {
        padding: "0 4px",
        marginBottom: "20px"
    });

    // Label row: "YEAR" on the left and current selected year on right
    const labelRow = document.createElement("div");
    Object.assign(labelRow.style, {
        display: "flex",
        justifyContent: "space-between",
        alignItems: "baseline",
        marginBottom: "8px"
    });

    const label = document.createElement("span");
    label.textContent = "Year";
    Object.assign(label.style, {
        fontSize: "13px",
        fontWeight: "600",
        color: "#045B4C",
        textTransform: "uppercase",
        letterSpacing: "0.5px"
    }); 

    // The big year number shown next to the label
    const yearDisplay = document.createElement("span");
    yearDisplay.textContent = currentYear;
    Object.assign(yearDisplay.style, {
        fontSize: "18px",
        fontWeight: "700",
        color: "#045B4C",
        fontVariantNumeric: "tabular-nums"  // prevents layout jumpyness as digits change
    });

    // Place them in the container
    labelRow.appendChild(label);
    labelRow.appendChild(yearDisplay);

    // Make the actual slider
    const slider = document.createElement("input");
    slider.type = "range";
    slider.min = 0; // we are indexing into years, with 0 being the first row
    slider.max = years.length - 1;
    slider.value = years.indexOf(currentYear);
    slider.step = 1;
    Object.assign(slider.style, {
        width: "100%",
        accentColor: "#045B4C",
        cursor: "pointer"
    });

    // Min/max year labels underneath slider
    const rangeLabels = document.createElement("div");
    Object.assign(rangeLabels.style, {
        display: "flex",
        justifyContent: "space-between",
        fontSize: "11px",
        color: "#999",
        marginTop: "4px"
    });
    // Create label based on years represented in data
    rangeLabels.innerHTML = `<span>${years[0]}</span><span>${years[years.length - 1]}</span>`;

    // Update year display and map when slider moves
    slider.addEventListener("input", () => {
        const year = years[parseInt(slider.value)];
        yearDisplay.textContent = year;
        onChange(year); // this will update the map
    });

    // Put it all together
    wrapper.appendChild(labelRow);
    wrapper.appendChild(slider);
    wrapper.appendChild(rangeLabels);

    return wrapper;
} // END Year slider builder

// ===================================================
// ===================================================
// RECRUITMENT COLOR SCALE 
//
// Maps an index value to a color based on BA's established bins
// Writing as a function because it will be called each time the 
// year slider slides
//
// Bins:
//   No data: grey
//   0: pale yellow
//   0-1: light yellow
//   1-2: yellow-orange
//   2-3: orange
//   3-5: dark orange
//   5-10: red-orange
//   10-20: dark red
//   >=20: deep red
// ===================================================
// ===================================================
function spatToColor(value, maxValue) {
    // No data
    if (value === null || isNaN(value)) return "#c8c8c8";

    // Assign color by bin
    if (value === 0)        return "#ffffcc";  // 0
    if (value <= 1)         return "#ffeda0";  // 0–1
    if (value <= 2)         return "#fed976";  // 1–2
    if (value <= 3)         return "#feb24c";  // 2–3
    if (value <= 5)         return "#fd8d3c";  // 3–5
    if (value <= 10)        return "#f03b20";  // 5–10
    if (value <= 20)        return "#bd0026";  // 10–20
    return                         "#67000d";  // >=20
} // END recruitment color scale

// Circle radius scaled to index value
function spatToRadius(value) {
    if (value === null || isNaN(value)) return 5;
    if (value === 0) return 5;
    return 5 + Math.sqrt(value) * 1.8;
}

// ===================================================
// ===================================================
// RECRUITMENT STATION DETAIL PANEL
//
// Panel similar to enhancement site stories
// Pops out from right side when recruitment station clicked
// Shows line plot of recruitment over time for all sites with
// selected site highlighted
//
// Arguments:
//   station: the station row object from the CSV
//   allData: full recruitment CSV
//   detailContainer: the existing detail panel div to populate
//   map: the Leaflet map
//   mainContainer / mapContainer: for layout shift (same
//                 pattern as showDetail() in enhancement tab)
//   resetView: the existing resetView() function to reuse
// ===================================================
// ===================================================
function showRecruitmentDetail(station, allData, detailContainer, map, mainContainer, mapContainer, resetView) {

    // Filter to current station and sort by year
    const stationData = allData
        .filter(d => d.standard_station === station.standard_station && d.year && d.index != null)
        .sort((a, b) => a.year - b.year);

    // Add some summary stats
    const avgAll = stationData.reduce((s, d) => s + d.index, 0) / (stationData.length || 1);
    const maxYear = stationData.reduce((best, d) => d.index > best.index ? d : best, stationData[0]);
    const minYear = stationData.reduce((worst, d) => d.index < worst.index ? d : worst, stationData[0]);

    // -----------------------------------------------
    // Shift layout: map shrinks to 30%, panel appears
    // (same pattern to showDetail() in enhancement tab)
    // -----------------------------------------------
    mainContainer.style.display = "flex";
    mainContainer.style.gap = "10px";
    mainContainer.classList.add("detail-open");
    mapContainer.style.width = "30%";
    mapContainer.style.flexShrink = "0";
    detailContainer.style.display = "flex";
    setTimeout(() => detailContainer.style.opacity = "1", 10);

    // Wait for the map container's width transition to actually finish
    // before telling Leaflet to resize + recenter — same fix as showDetail()
    const handleRecruitResize = (e) => {
        // Only react to the width transition, not other properties
        if (e.propertyName !== "width") return;
        mapContainer.removeEventListener("transitionend", handleRecruitResize);
        map.invalidateSize({ pan: false });
        map.setView(
            [station.latitude, parseFloat(station.longitude)],
            13,
            { animate: false }
        );
    };
    mapContainer.addEventListener("transitionend", handleRecruitResize);

    // Fallback in case transitionend doesn't fire (e.g. width was
    // already 30% and no transition actually occurs)
    setTimeout(() => {
        mapContainer.removeEventListener("transitionend", handleRecruitResize);
        map.invalidateSize({ pan: false });
        map.setView(
            [station.latitude, parseFloat(station.longitude)],
            13,
            { animate: false }
        );
    }, 300); // slightly longer than the 0.25s CSS transition

    // Clear any previously shown content
    detailContainer.innerHTML = "";

    // -----------------------------------------------
    // Button bar (non-scrolling top strip)
    // Reuses the same structure as the enhancement panel
    // -----------------------------------------------
    const buttonBar = document.createElement("div");
    Object.assign(buttonBar.style, {
        flexShrink: "0",
        padding: "16px 20px",
        borderBottom: "1px solid #e0e0e0",
        backgroundColor: "white",
        borderRadius: "8px 8px 0 0",
        zIndex: "10",
        display: "flex",
        alignItems: "center",
        justifyContent: "space-between"
    });

    // Back button: calls the shared resetView() defined in oysterMap()
    const backButton = document.createElement("button");
    backButton.textContent = "← Back to Map";
    Object.assign(backButton.style, {
        padding: "10px 20px",
        cursor: "pointer",
        border: "2px solid #045B4C",
        borderRadius: "6px",
        backgroundColor: "white",
        color: "#045B4C",
        fontSize: "14px",
        fontWeight: "600",
        transition: "all 0.2s ease",
        textTransform: "uppercase",
        letterSpacing: "0.5px"
    });
    backButton.onmouseenter = () => { backButton.style.backgroundColor = "#045B4C"; backButton.style.color = "white"; };
    backButton.onmouseleave = () => { backButton.style.backgroundColor = "white";   backButton.style.color = "#045B4C"; };
    backButton.onclick = resetView;

    const stationTitle = document.createElement("h2");
    stationTitle.textContent = station.standard_station;
    Object.assign(stationTitle.style, {
        margin: "0",
        fontSize: "22px",
        fontWeight: "700",
        color: "#045B4C",
        letterSpacing: "0.5px",
        textAlign: "right"
    });

    buttonBar.appendChild(backButton);
    buttonBar.appendChild(stationTitle);

    // -----------------------------------------------
    // Scrollable body
    // -----------------------------------------------
    const scrollBody = document.createElement("div");
    Object.assign(scrollBody.style, {
        flexGrow: "1",
        overflowY: "auto",
        overflowX: "hidden",
        padding: "20px",
        boxSizing: "border-box"
    });

    // Tag showing this is recruitment data (not an enhancement story)
    const tag = document.createElement("div");
    tag.textContent = "Recruitment Monitoring Station";
    Object.assign(tag.style, {
        display: "inline-block",
        fontSize: "11px",
        fontWeight: "600",
        color: "#045B4C",
        background: "#e8f4f2",
        padding: "4px 10px",
        borderRadius: "20px",
        textTransform: "uppercase",
        letterSpacing: "0.5px",
        marginBottom: "20px"
    });
    scrollBody.appendChild(tag);

    // -----------------------------------------------
    // Summary stats callout row
    // Three boxes: average, best year, worst year
    // -----------------------------------------------
    if (stationData.length > 0) {
        const statsRow = document.createElement("div");
        Object.assign(statsRow.style, {
            display: "grid",
            gridTemplateColumns: "repeat(3, 1fr)",
            gap: "10px",
            marginBottom: "28px"
        });

        const stats = [
            { label: "All-time avg",  value: avgAll.toFixed(2),          unit: "live olys / shell" },
            { label: "Best year",     value: maxYear ? maxYear.year : "—", unit: maxYear ? `${parseFloat(maxYear.index).toFixed(2)} live olys` : "" },
            { label: "Lowest year",   value: minYear ? minYear.year : "—", unit: minYear ? `${parseFloat(minYear.index).toFixed(2)} live olys` : "" }
        ];

        stats.forEach(stat => {
            const box = document.createElement("div");
            Object.assign(box.style, {
                background: "linear-gradient(135deg, #e8f4f2 0%, #f0f7f6 100%)",
                borderRadius: "8px",
                padding: "14px 12px",
                textAlign: "center"
            });
            box.innerHTML = `
                <div style="font-size:11px; font-weight:600; color:#045B4C;
                    text-transform:uppercase; letter-spacing:0.5px; margin-bottom:6px;">${stat.label}</div>
                <div style="font-size:22px; font-weight:700; color:#045B4C;
                    font-variant-numeric:tabular-nums;">${stat.value}</div>
                <div style="font-size:11px; color:#777; margin-top:3px;">${stat.unit}</div>
            `;
            statsRow.appendChild(box);
        });

        scrollBody.appendChild(statsRow);
    }

    // -----------------------------------------------
    // Comparison option: controls which sites appear as
    // grey comparison lines behind the highlighted site
    // Options: this site only, waterbody, basin, all sites
    // -----------------------------------------------

    // Label explaining what the comparison pills do
    const compareLabel = document.createElement("div");
    Object.assign(compareLabel.style, {
        fontSize: "12px",
        fontWeight: "600",
        color: "#045B4C",
        textTransform: "uppercase",
        letterSpacing: "0.5px",
        marginBottom: "6px"
    });
    compareLabel.textContent = "Compare Against";

    const compareHint = document.createElement("p");
    Object.assign(compareHint.style, {
        fontSize: "12px",
        color: "#777",
        margin: "0 0 10px 0",
        lineHeight: "1.5"
    });
    compareHint.textContent = "Use these buttons to compare the current station to other stations in the same waterbody, basin, or all of Puget Sound.";
    

    const scopeWrapper = document.createElement("div");
    Object.assign(scopeWrapper.style, {
        marginBottom: "16px",
        display: "flex",
        gap: "8px",
        flexWrap: "wrap"
    });

    const scopes = [
        { id: "station", label: "Current Station" },
        { id: "waterbody", label: `${station.waterbody} Stations` },
        { id: "basin", label: `${station.basin} Stations` || "Basin" },
        { id: "sound", label: "All Stations" }
    ];

    let currentScope = "station";

    // Build one pill button per scope
    const scopeBtns = {};
    scopes.forEach(scope => {
        const btn = document.createElement("button");
        btn.textContent = scope.label;
        Object.assign(btn.style, {
            padding: "6px 14px",
            border: "2px solid #045B4C",
            borderRadius: "20px",
            fontSize: "12px",
            fontWeight: "600",
            cursor: "pointer",
            transition: "all 0.2s ease",
            backgroundColor: scope.id === "station" ? "#045B4C" : "white",
            color: scope.id === "station" ? "white" : "#045B4C"
        });
        btn.addEventListener("click", () => {
            currentScope = scope.id;
            // Update button styles
            Object.entries(scopeBtns).forEach(([id, b]) => {
                b.style.backgroundColor = id === scope.id ? "#045B4C" : "white";
                b.style.color           = id === scope.id ? "white"   : "#045B4C";
            });
            renderChart();
        });
        scopeBtns[scope.id] = btn;
        scopeWrapper.appendChild(btn);
    });
    

    // Chart container: gets rebuilt by renderChart() on scope change
    const chartWrapper = document.createElement("div");
    Object.assign(chartWrapper.style, {
        background: "white",
        padding: "20px",
        borderRadius: "8px",
        boxShadow: "0 2px 8px rgba(0,0,0,0.08)",
        marginBottom: "24px"
    });
    scrollBody.appendChild(chartWrapper);
    scrollBody.appendChild(compareLabel);
    scrollBody.appendChild(compareHint);
    scrollBody.appendChild(scopeWrapper);

    // -----------------------------------------------
    // Clip y axis max
    // Computed once from ALL stations 
    // keeps the "All Stations" comparison as the hard upper bound
    // -----------------------------------------------
    const allStationsIndexValues = allData
        .map(d => d.index)
        .filter(v => v !== null && !isNaN(v))
        .sort((a, b) => a - b);

    const fixedClipCeiling = (allStationsIndexValues[Math.floor(allStationsIndexValues.length * 0.99)] || 10) * 1.08;

    // -----------------------------------------------
    // renderChart: builds the Plot chart for the
    // current scope. Called on load and on scope change.
    // -----------------------------------------------
    function renderChart() {
        chartWrapper.innerHTML = `
            <h3 style="font-size:15px; font-weight:700; color:#045B4C;
                margin:0 0 4px 0; text-transform:uppercase; letter-spacing:0.5px;">
                Recruitment Over Time
            </h3>
            <p style="font-size:13px; color:#666; margin:0 0 16px 0; font-style:italic;">
                Average live olys per shell per year
            </p>
        `;

        // Filter comparison sites based on selected scope
        // allData is the full recruitment dataset passed into showRecruitmentDetail
        const comparisonStations = currentScope === "station"
            ? []   // no comparison lines for "this station only"
            : allData.filter(d => {
                if (currentScope === "waterbody") 
                    return d.waterbody === station.waterbody && d.standard_station !== station.standard_station;
                if (currentScope === "basin") 
                    return d.basin === station.basin && d.standard_station !== station.standard_station;
                if (currentScope === "sound") 
                    return d.standard_station !== station.standard_station;
                return false;
            });

        // Get unique comparison station names
        const compStationNames = [...new Set(comparisonStations.map(d => d.standard_station))];

        // Build comparison line data: one array per station
        // Each array is that station's full time series
        const compLines = compStationNames.map(s =>
            allData
                .filter(d => d.standard_station === s && d.year && d.index !== null && !isNaN(d.index))
                .sort((a, b) => a.year - b.year)
        ).filter(arr => arr.length > 1);  // skip stations with only one data point

        // Compute global y-max across highlighted + comparison stations
        // Cap at 99th percentile to prevent extreme outliers messing with the scale
        const allIndexValues = [
            ...stationData.map(d => d.index),
            ...compLines.flat().map(d => d.index)
        ].filter(v => v !== null && !isNaN(v)).sort((a, b) => a - b);

        const scopedYMax = (allIndexValues[Math.floor(allIndexValues.length * 0.99)] || 10);

        const yMax = Math.min(scopedYMax, fixedClipCeiling);

        // Clamp comparison line data to yMax so lines end at the plot boundary
        // rather than escaping above it. We clamp each point individually.
        const compLinesClamped = compLines.map(lineData =>
            lineData.map(d => ({...d, indexClamped: Math.min(d.index, yMax)}))
        );

        // For arrow markers: find the points in each series that exceed yMax
        const arrowPoints = compLinesClamped.flatMap(lineData =>
            lineData.filter(d => d.index > yMax)
        );
        const arrowPointsHighlighted = stationData
            .filter(d => d.index > yMax)
            .map(d => ({...d, indexClamped: yMax}));
        const allArrowPoints = [...arrowPoints, ...arrowPointsHighlighted];

        if (stationData.length > 1) {
            const chart = Plot.plot({
                height: 260,
                marginLeft: 50,
                marginRight: 20,
                marginTop: 25,
                marginBottom: 40,
                insetTop: 15,
                x: {
                    label: null,
                    tickFormat: "d",
                    interval: 1,
                    insetLeft: 15,
                    domain: [2014, Math.max(...allData.map(d => d.year))]
                },
                y: {
                    label: "Avg live olys / shell",
                    labelAnchor: "top",
                    grid: true,
                    nice: true, 
                    domain: [0, yMax]
                },
                marks: [
                       // Comparison lines — clamped to yMax at the boundary
                    ...compLinesClamped.map(lineData =>
                        Plot.lineY(lineData, {
                            x: "year",
                            y: "indexClamped",
                            stroke: "#ccc",
                            strokeWidth: 1.5,
                            opacity: 0.6
                        })
                    ),

                    // Arrow at the top of any clamped line
                    allArrowPoints.length > 0 ? Plot.text(allArrowPoints, {
                        x: "year",
                        y: () => yMax,
                        text: () => "^",
                        fontSize: 20,
                        fontWeight: "bold",
                        fill: d => d.standard_station === station.standard_station ? "#045B4C" : "#bbb",
                        stroke: "white",
                        strokeWidth: 3,
                        dy: -2
                    }) : null,

                    // Comparison dots — clamped, but skip points that have an arrow
                    ...compLinesClamped.map(lineData =>
                        Plot.dot(lineData.filter(d => d.index <= yMax), {
                            x: "year",
                            y: "indexClamped",
                            fill: "#ccc",
                            stroke: "white",
                            strokeWidth: 2,
                            r: 4
                        })
                    ),

                        // Highlighted line — clamped
                        Plot.lineY(
                            stationData.map(d => ({...d, indexClamped: Math.min(d.index, yMax)})),
                            {
                                x: "year",
                                y: "indexClamped",
                                stroke: "#045B4C",
                                strokeWidth: 2.5
                            }
                        ),

                        // Highlighted dots — clamped, skip points that have an arrow
                        Plot.dot(
                            stationData
                                .map(d => ({...d, indexClamped: Math.min(d.index, yMax)}))
                                .filter(d => d.index <= yMax),
                            {
                                x: "year",
                                y: "indexClamped",
                                fill: "#045B4C",
                                stroke: "white",
                                strokeWidth: 2,
                                r: 4
                            }
                        ),

                        // Unified tooltip — highlighted station rows are duplicated first
                        // so Plot.pointer() snaps to them preferentially when close
                        Plot.tip(
                            [...stationData, ...compLines.flat()].filter(d => d.index <= yMax),
                            Plot.pointer({
                                x: "year",
                                y: "index",
                                title: d => d.standard_station === station.standard_station
                                    ? `★ ${d.standard_station.replaceAll("_", " ")}\n${d.year}: ${d.index} avg live olys/shell`
                                    : `${d.standard_station.replaceAll("_", " ")}\n${d.year}: ${d.index} avg live olys/shell`
                            })
                        ),

                        // Tooltip on arrow points showing the true clipped value
                    allArrowPoints.length > 0 ? Plot.tip(allArrowPoints, Plot.pointer({
                        x: "year",
                        y: () => yMax,
                        title: d => `${d.standard_station.replaceAll("_", " ")} (off scale)\n${d.year}: ${d.index} avg live olys/shell`
                    })) : null
                    ],
                    style: { fontFamily: "inherit", fontSize: "13px" }
                });

            chartWrapper.appendChild(chart);

            // Note about outliers being clipped if any exist above yMax
            const clippedCount = allIndexValues.filter(v => v > yMax).length;
            const avgNote = document.createElement("p");
            avgNote.style.margin = "8px 0 0 0";
            avgNote.innerHTML = `
                <span style="font-size:12px; color:#777;">
                    ${clippedCount > 0 ? ` &nbsp;·&nbsp; ${clippedCount} outlier value${clippedCount > 1 ? "s" : ""} clipped from view` : ""}
                </span>`;
            chartWrapper.appendChild(avgNote);

        } else {
            const noData = document.createElement("p");
            noData.textContent = stationData.length === 1
                ? `Only one year of data available (${stationData[0].year}: ${stationData[0].index.toFixed(1)} live olys/shell).`
                : "No recruitment data recorded for this station.";
            Object.assign(noData.style, { fontSize: "13px", color: "#999", fontStyle: "italic", margin: "0" });
            chartWrapper.appendChild(noData);
        }
    }

    // Render on first load
    renderChart();

    // Assemble and show
    detailContainer.appendChild(buttonBar);
    detailContainer.appendChild(scrollBody);


} // END recruitment detail panel function


// ===================================================
// ===================================================
// RECRUITMENT MAP LAYER MANAGER
//
// Places recruitment icons on map
// Updates size and color when year selector changes
// ===================================================
// ===================================================
function createRecruitmentLayerManager(recruitData, recruitLayer, map, onStationClick) {

    // -----------------------------------------------
    // Group data by year
    // byYear[2015] = [ ...all rows for 2015... ]
    // -----------------------------------------------
    const byYear = {};
    recruitData.forEach(row => {
        if (!row.year) return;
        if (!byYear[row.year]) byYear[row.year] = [];
        byYear[row.year].push(row);
    });

    // Sorted list of all unique years
    const years = Object.keys(byYear).map(Number).sort((a, b) => a - b);

    // Build deduplicated station lookup: stationName -> { lat, lng }
    const stationInfo = {};
    const seen = new Set();
    recruitData.forEach(row => {
        if (seen.has(row.standard_station)) return;
        if (!row.latitude || !row.longitude ||
            row.latitude === "NA" || row.longitude === "NA" ||
            isNaN(parseFloat(row.latitude))) return;
        seen.add(row.standard_station);
        stationInfo[row.standard_station] = {
            lat: parseFloat(row.latitude),
            lng: parseFloat(row.longitude)
        };
    });

    
    // -----------------------------------------------
    // Store the markers
    // -----------------------------------------------
    const individualMarkers  = {};  // station name - L.circleMarker

    // Track which mode we're in
    let currentYear = years[years.length - 1];  // start at latest year

    // -----------------------------------------------
    // HELPER: build yearData lookup for a given year
    // -----------------------------------------------
    function getYearData(year) {
        const yearData = {};
        (byYear[year] || []).forEach(row => {
            yearData[row.standard_station] = row;
        });
        return yearData;
    }

    // -----------------------------------------------
    // Build markers
    // -----------------------------------------------
    function init() {

        // --- Build individual station markers ---
        Object.entries(stationInfo).forEach(([stationName, info]) => {
            // Find a full row for this station to pass to onStationClick
            const stationRow = recruitData.find(d => d.standard_station === stationName);

            const marker = L.circleMarker([info.lat, info.lng], {
                radius: 7,
                fillColor: "#e0e0e0",
                color: "#999",
                weight: 1.5,
                opacity: 1,
                fillOpacity: 0.5
            });

            marker.bindTooltip(`
                <div style="padding:10px 12px; min-width:160px;">
                    <p style="font-size:13px; font-weight:600; color:#222;
                        margin:0 0 4px 0; text-align:center;">
                        ${stationName.replaceAll("_", " ")}
                    </p>
                    <p style="font-size:11px; color:#888; text-align:center;
                        margin:0; text-transform:uppercase; letter-spacing:0.4px;">
                        Recruitment Station
                    </p>
                </div>
            `, {
                direction: "top",
                permanent: false,
                className: "custom-tooltip"
            });

            marker.on("click", () => onStationClick(stationRow));
            marker.on("mouseover", () => {
                if (marker.getElement()) marker.getElement().style.cursor = "pointer";
            });

            marker.addTo(recruitLayer);
            individualMarkers[stationName] = marker;        
        });


        // Start with most recent year of data shown
        updateYear(currentYear);
            
    }

    // -----------------------------------------------
    // UPDATE YEAR
    // Re-styles markers for the newly selected year
    // -----------------------------------------------
    function updateYear(year) {
        currentYear = year;
        const yearData = getYearData(year);

        Object.entries(individualMarkers).forEach(([stationName, marker]) => {
            const row = yearData[stationName];
            const value = (row && row.index !== null && !isNaN(row.index)) ? row.index : null;

            marker.setRadius(spatToRadius(value));
            marker.setStyle({
                fillColor: spatToColor(value),
                color: value !== null ? "white" : "#999",
                weight: 1.5,
                opacity: 1,
                fillOpacity: value !== null ? 0.9 : 0.5
            });

            marker.setTooltipContent(
                value !== null ? `
                    <div style="padding:10px 12px; min-width:180px;">
                        <p style="font-size:13px; font-weight:600; color:#222;
                            margin:0 0 6px 0; text-align:center;">
                            ${stationName.replaceAll("_", " ")}
                        </p>
                        <div style="height:1px; background:#e8e8e8; margin:0 0 6px 0;"></div>
                        <div style="display:flex; justify-content:space-between;
                            font-size:12px; color:#555;">
                            <span style="color:#045B4C; font-weight:600;">${year}</span>
                            <span>${value} avg live olys/shell</span>
                        </div>
                    </div>
                ` : `
                    <div style="padding:10px 12px; min-width:160px;">
                        <p style="font-size:13px; font-weight:600; color:#222;
                            margin:0 0 4px 0; text-align:center;">
                            ${stationName.replaceAll("_", " ")}
                        </p>
                        <p style="font-size:12px; color:#aaa; text-align:center; margin:0;">
                            No data for ${year}
                        </p>
                    </div>
                `
            );
        });

        // ===============================================
        // Layering Recruitment Markers
        // Reorders markers so that:
        //   1. "No data" stations always sit at the very back
        //   2. Among stations with data, larger index values
        //      are drawn first (bottom) and smaller values are
        //      drawn last (top), so a big circle shouldn't fully
        //      swallow a smaller one sitting near it
        // Must run every time updateYear() runs
        // ===============================================

        const noDataMarkers = [];
        const dataMarkers = [];

        Object.entries(individualMarkers).forEach(([stationName, marker]) => {
            const row = yearData[stationName];
            const value = (row && row.index !== null && !isNaN(row.index)) ? row.index : null;

            if (value === null) {
                noDataMarkers.push(marker);
            } else {
                dataMarkers.push({ marker, value });
            }
        });

        // Push every "no data" marker to the very back
        noDataMarkers.forEach(marker => marker.bringToBack());

        // Sort data markers largest to smallest, then call bringToFront()
        // Each bringToFront() call stacks the marker above everything 
        // currently in front of it, so the last one called (the smallest 
        // value) ends up on top of the pile
        dataMarkers
            .sort((a, b) => b.value - a.value) // descending: biggest first
            .forEach(({ marker }) => marker.bringToFront());
    } // END updateYear

    // Show
    return { years, updateYear, init };

} // END Recruitment layer manager function

// ===================================================
// ===================================================
// MAP LEGEND BUILDER: RECRUITMENT
//
// Arguments:
//   map: Leaflet map instance
//   maxValue: global max spat value (for scale labels)
// ===================================================
// ===================================================
function addRecruitmentLegend(map, maxValue) {
    const legend = L.control({ position: "topright" });

    legend.onAdd = function() {
        const div = L.DomUtil.create("div", "recruit-legend");

        div.innerHTML = `
            <div class="map-legend-box recruit-legend-box">
                <div class="map-legend-header">
                    <span>Avg Live Olys / Shell</span>
                    <button class="legend-toggle-btn" type="button" aria-label="Toggle legend">−</button>
                </div>
                <div class="map-legend-body">
                    ${[
                        { color: "#c8c8c8", label: "No data" },
                        { color: "#ffffcc", label: "0" },
                        { color: "#ffeda0", label: "0 – 1" },
                        { color: "#fed976", label: "1 – 2" },
                        { color: "#feb24c", label: "2 – 3" },
                        { color: "#fd8d3c", label: "3 – 5" },
                        { color: "#f03b20", label: "5 – 10" },
                        { color: "#bd0026", label: "10 – 20" },
                        { color: "#67000d", label: "≥ 20" },
                    ].map(bin => `
                        <div class="map-legend-row">
                            <span class="map-legend-swatch" style="background:${bin.color};"></span>
                            <span>${bin.label}</span>
                        </div>
                    `).join("")}
                </div>
            </div>
        `;

        const box = div.querySelector('.map-legend-box');
        const toggleBtn = div.querySelector('.legend-toggle-btn');
        toggleBtn.addEventListener('click', (e) => {
            e.stopPropagation();
            box.classList.toggle('collapsed');
            toggleBtn.textContent = box.classList.contains('collapsed') ? '+' : '−';
        });

        L.DomEvent.disableClickPropagation(div);
        return div;
    };

    legend.addTo(map);
    return legend; // return so we can .remove() it when switching tabs
} // END recruitment legend builder



// ===================================================
// ===================================================
// ENHANCEMENT TAB CONTENT BUILDER
// Builds the "Read a Story" dropdown and the
// enhancement-type toggle buttons, and wires up all
// their interactivity.
// ===================================================
// ===================================================
function buildEnhancementTabContent(enhData, map, story_sites) {
    const content = document.createElement("div");
    content.className = "filter-tab-content";

    // Write all static HTML for this tab
    content.innerHTML = `
            <div class="filter-divider"></div>

            <!-- Story Site Dropdown (static HTML here, dynamic content added below) -->
            <div class="filter-section">
                <label class="filter-section-label">Read a Story</label>
                <select id="site-selector" class="filter-select">
                    <option value="">Select a site...</option>
                </select>
                <div class="filter-hint">Zoom to a site and view its story</div>
            </div>

            <div class="filter-divider"></div>

            <!-- Enhancement Type filter: oblong toggle buttons -->
            <div class="filter-section">
                <label class="filter-section-label">Filter by Enhancement Type</label>
                <div style="display: flex; flex-wrap: wrap; gap: 8px; margin-bottom: 8px;">
                    <!-- Each button has a "data-type" attribute -->
                    <button class="type-toggle-btn" data-type="bulk shell">Bulk Shell</button>
                    <button class="type-toggle-btn" data-type="seeded cultch">Seeded Cultch</button>
                    <button class="type-toggle-btn" data-type="singles">Singles</button>
                </div>
                <div class="filter-hint">Select which enhancement methods are displayed</div>
            </div>
    `;

    // -----------------------------------------------
    // Site selector: populate dropdown, wire up navigation
    // -----------------------------------------------
    const siteSelector = content.querySelector('#site-selector');

    // Track currently open enhancement tooltip so we can
    // close it before opening a new one
    let currentOpenMarker = null;

    // Build the list of sites to show in the dropdown
    // Only include sites that have valid coordinates and are in story_sites
    const uniqueSites = [...new Set(
        enhData
            .filter(site =>
                site.latitude && site.longitude &&
                site.latitude !== 'NA' && site.longitude !== 'NA' &&
                !isNaN(parseFloat(site.latitude)) && !isNaN(parseFloat(site.longitude)) &&
                story_sites.has(site.site_name)
            )
            .map(site => site.site_name)
    )].sort(); // Alphabetize

    // For each site name, create an option element
    uniqueSites.forEach(siteName => {
        const option = document.createElement('option');
        option.value = siteName;
        option.textContent = siteName;
        siteSelector.appendChild(option);
    });

    // Listen for when the user selects a site from the dropdown
    siteSelector.addEventListener('change', (e) => {
        const selectedSite = e.target.value;

        // Only proceed if something was selected AND that site has a marker on the map
        if (selectedSite && window.markersBySite[selectedSite]) {
            const marker = window.markersBySite[selectedSite];
            const latLng = marker.getLatLng();

            // If a tooltip is already open, close it before opening a new one!!!
            if (currentOpenMarker) currentOpenMarker.closeTooltip();

            // Recenter the map on this site. animate:true makes it look nice!
            map.setView(latLng, 12, { animate: true, duration: 0.5 });

            // Wait 600ms for the zoom animation to finish, then open the tooltip
            setTimeout(() => {
                marker.openTooltip();
                currentOpenMarker = marker;
            }, 600);
        }
    });

    // When the user zooms out past zoom level 11,
    // reset the dropdown back to the placeholder "Select a site..." option
    map.on('zoomend', () => {
        if (map.getZoom() < 11) siteSelector.value = '';
    });

    // -----------------------------------------------
    // Enhancement type toggle buttons
    // -----------------------------------------------

    // Start with all 3 enhancement buttons as active
    const activeTypes = new Set(['bulk shell', 'seeded cultch', 'singles']);

    // Take the enhancement_actions column from the CSV and split into an array of strings
    // eg. "bulk shell, seeded cultch" to ["bulk shell", "seeded cultch"]
    function normalizeType(typeString) {
        if (!typeString) return [];
        return typeString.split(',').map(t => t.trim().toLowerCase()).filter(t => t.length > 0);
    }

    // Loop through all enhancement sites and show/hide markers
    // based on if it is selected or not
    function filterEnhancementMarkers(enhancementLayer) {
        enhData.forEach(site => {
            const marker = window.markersBySite[site.site_name];
            if (marker) {
                const siteTypes = normalizeType(site.enhancement_actions);
                const shouldShow = siteTypes.some(type => activeTypes.has(type));

                if (shouldShow) {
                    if (!enhancementLayer.hasLayer(marker)) enhancementLayer.addLayer(marker);
                } else {
                    if (enhancementLayer.hasLayer(marker)) enhancementLayer.removeLayer(marker);
                }
            }
        });
    }

    const typeToggleBtns = content.querySelectorAll('.type-toggle-btn');

    typeToggleBtns.forEach(btn => {
        // When a button is clicked toggle it in and out of the activeTypes
        btn.addEventListener('click', () => {
            const type = btn.getAttribute('data-type');

            if (activeTypes.has(type)) {
                activeTypes.delete(type);
                btn.classList.add('inactive');
            } else {
                activeTypes.add(type);
                btn.classList.remove('inactive');
            }

            // Re-run the marker filter with the updated activeTypes set —
            // enhancementLayer is attached here on first use, set by createFilterPanel
            filterEnhancementMarkers(content._enhancementLayer);
        });
    });

    return { element: content, siteSelector };
} // END buildEnhancementTabContent

// ===================================================
// ===================================================
// RECRUITMENT TAB CONTENT BUILDER
// Builds the waterbody jump dropdown, year slider,
// and click hint, and wires up all their interactivity.
// ===================================================
// ===================================================
function buildRecruitmentTabContent(recruitData, recruitLayerManager, map) {
    const content = document.createElement("div");
    content.className = "filter-tab-content hidden"; // hidden by default — enhancement starts active

    // -----------------------------------------------
    // Waterbody jump dropdown (only shows waterbodies that have coordinates)
    // -----------------------------------------------
    const wbDropdownWrapper = document.createElement("div");
    wbDropdownWrapper.className = "filter-section";
    wbDropdownWrapper.innerHTML = `
        <label style="display:block; font-size:13px; font-weight:600; color:#045B4C;
            margin-bottom:8px; text-transform:uppercase; letter-spacing:0.5px;">Jump to Waterbody</label>
        <select id="waterbody-selector" class="filter-select">
            <option value="">Select a waterbody...</option>
        </select>
        <div class="filter-hint">Zoom to a waterbody and view its stations</div>
    `;

    // Populate the dropdown from the recruitment data
    const uniqueWaterbodies = [...new Set(
        recruitData
            .filter(d => d.waterbody && d.latitude && d.latitude !== "NA")
            .map(d => d.waterbody)
    )].sort();

    const wbSelector = wbDropdownWrapper.querySelector("#waterbody-selector");
    uniqueWaterbodies.forEach(wb => {
        const option = document.createElement("option");
        option.value = wb;
        option.textContent = wb;
        wbSelector.appendChild(option);
    });

    // When a waterbody is selected, zoom the map to fit its stations
    wbSelector.addEventListener("change", (e) => {
        const wb = e.target.value;
        if (!wb) return;

        const stations = recruitData.filter(d =>
            d.waterbody === wb &&
            d.latitude && d.latitude !== "NA" &&
            !isNaN(parseFloat(d.latitude))
        );

        if (stations.length === 0) return;

        const lats = stations.map(d => parseFloat(d.latitude));
        const lngs = stations.map(d => parseFloat(d.longitude));

        map.fitBounds(
            L.latLngBounds(
                [Math.min(...lats) - 0.02, Math.min(...lngs) - 0.02],
                [Math.max(...lats) + 0.02, Math.max(...lngs) + 0.02]
            ),
            { animate: true, padding: [30, 30] }
        );
    });

    // Reset dropdown when user zooms back out
    map.on("zoomend", () => {
        if (map.getZoom() < 10) wbSelector.value = "";
    });

    // -----------------------------------------------
    // Year slider
    // -----------------------------------------------
    const sliderContainer = document.createElement("div");
    sliderContainer.className = "filter-section";

    if (recruitLayerManager && recruitLayerManager.years.length > 0) {
        const years = recruitLayerManager.years;
        const latestYear = years[years.length - 1];

        const slider = buildYearSlider(years, latestYear, (year) => {
            recruitLayerManager.updateYear(year);
        });
        sliderContainer.appendChild(slider);
        recruitLayerManager.updateYear(latestYear);
    }

    const sliderNote = document.createElement("p");
    sliderNote.className = "filter-hint";
    sliderNote.style.margin = "4px 0 0 0";
    sliderNote.textContent = "Drag the slider to explore recruitment across different years. Circle size and color reflect the average number of olys settled per shell at each station.";
    sliderContainer.appendChild(sliderNote);

    // -----------------------------------------------
    // Note about clicking stations
    // -----------------------------------------------
    const clickHint = document.createElement("div");
    clickHint.className = "filter-section";
    clickHint.innerHTML = `
        <div class="filter-click-hint">▶ Click any station to view its recruitment history</div>
    `;

    // -----------------------------------------------
    // Assemble all sections with dividers
    // -----------------------------------------------
    const divider1 = document.createElement("div");
    divider1.className = "filter-divider";
    content.appendChild(divider1);

    content.appendChild(wbDropdownWrapper);

    const divider2 = document.createElement("div");
    divider2.className = "filter-divider";
    content.appendChild(divider2);

    content.appendChild(sliderContainer);

    const divider3 = document.createElement("div");
    divider3.className = "filter-divider";
    content.appendChild(divider3);

    content.appendChild(clickHint);

    return { element: content };
} // END buildRecruitmentTabContent

// ===================================================
// ===================================================
// TAB BAR BUILDER
// The two pill buttons at the top: "Enhancement" and
// "Recruitment". Enhancement starts active.
// ===================================================
// ===================================================
function buildTabBar() {
    const tabBar = document.createElement("div");
    Object.assign(tabBar.style, {
        display: "flex",
        flexWrap: "wrap",
        gap: "8px",
        marginBottom: "12px",
        marginTop: "12px"
    });

    // Helper: creates one tab button
    function makeTabBtn(label, tabId) {
        const btn = document.createElement("button");
        btn.textContent = label;
        btn.dataset.tab = tabId;
        btn.className = "filter-tab-btn";
        return btn;
    }

    const enhTab = makeTabBtn("Enhancement", "enhancement");
    const recruitTab = makeTabBtn("Recruitment", "recruitment");
    enhTab.classList.add("active"); // enhancement starts active

    tabBar.appendChild(enhTab);
    tabBar.appendChild(recruitTab);

    return { element: tabBar, enhTab, recruitTab };
} // END buildTabBar

// ===================================================
// ===================================================
// TAB SWITCHING LOGIC
// When a tab button is clicked:
//   - Update button styles (active vs inactive)
//   - Show/hide the right content section
//   - Add/remove the appropriate map layers
//   - Swap the legend
//   - Call onTabSwitch() so oysterMap() can respond
// ===================================================
// ===================================================
function wireTabSwitching({ enhTab, recruitTab, enh, recruit, enhancementLayer, recruitmentLayer, map, enhancementLegend, recruitLayerManager, onTabSwitch }) {
    // Track the active recruitment legend so we can remove it on tab switch
    let activeRecruitLegend = null;

    function switchTab(tabId) {
        // Update tab button styles
        [enhTab, recruitTab].forEach(btn => {
            btn.classList.toggle("active", btn.dataset.tab === tabId);
        });

        const showingEnhancement = tabId === "enhancement";

        // Show/hide the right content section
        enh.element.classList.toggle("hidden", !showingEnhancement);
        recruit.element.classList.toggle("hidden", showingEnhancement);

        if (showingEnhancement) {
            // Show enhancement layer, hide recruitment layer
            enhancementLayer.addTo(map);
            recruitmentLayer.remove();

            // Restore the original enhancement legend, remove recruitment legend
            if (activeRecruitLegend) {
                activeRecruitLegend.remove();
                activeRecruitLegend = null;
            }
            if (enhancementLegend) enhancementLegend.addTo(map);

        } else {
            // Show recruitment layer, hide enhancement layer
            recruitmentLayer.addTo(map);
            enhancementLayer.remove();

            // Remove enhancement legend, add recruitment legend
            if (enhancementLegend) enhancementLegend.remove();
            if (!activeRecruitLegend) {
                activeRecruitLegend = addRecruitmentLegend(map, recruitLayerManager.globalMax);
            }
        }

        // Notify oysterMap() of the switch (e.g. to close any open detail panel)
        if (onTabSwitch) onTabSwitch(tabId);
    }

    // Wire up click events on both tab buttons
    enhTab.addEventListener("click", () => switchTab("enhancement"));
    recruitTab.addEventListener("click", () => switchTab("recruitment"));
} // END wireTabSwitching

// ===================================================
// ===================================================
// FILTER PANEL
// Builds filter panel content all together
// 
// ===================================================
// ===================================================
function createFilterPanel(enhancementLayer, recruitmentLayer, map, enhData, recruitData, recruitLayerManager, enhancementLegend, onTabSwitch) {
    const panel = document.createElement("div");
    panel.style.padding = "0";

    // Header text above the tab buttons
    const tabHeader = document.createElement("div");
    tabHeader.style.cssText = "font-size:12px; font-weight:600; color:#045B4C; margin-bottom:8px; text-transform:uppercase; letter-spacing:0.5px;";
    tabHeader.textContent = "Choose Map View";
    panel.appendChild(tabHeader);

    // Tab bar (Enhancement / Recruitment pill buttons)
    const { element: tabBar, enhTab, recruitTab } = buildTabBar();
    panel.appendChild(tabBar);

    // Subtext explaining what each tab shows
    const tabSubtext = document.createElement("div");
    tabSubtext.style.cssText = "font-size:11px; color:#666; font-style:italic; line-height:1.6; margin-bottom:24px;";
    tabSubtext.textContent = "Enhancement shows restoration sites. Recruitment shows long-term monitoring stations tracking annual oyster settlement.";
    panel.appendChild(tabSubtext);

    // Build both tabs' content
    const enh = buildEnhancementTabContent(enhData, map, story_sites);
    const recruit = buildRecruitmentTabContent(recruitData, recruitLayerManager, map);

    // The enhancement tab's type-toggle filter needs a live reference to enhancementLayer
    enh.element._enhancementLayer = enhancementLayer;

    panel.appendChild(enh.element);
    panel.appendChild(recruit.element);

    // Wire up tab-switching behavior (layer swap, legend swap, styles)
    wireTabSwitching({
        enhTab, recruitTab, enh, recruit,
        enhancementLayer, recruitmentLayer, map,
        enhancementLegend, recruitLayerManager, onTabSwitch
    });

    return panel;
} // END FILTER PANEL FUNCTION

// ===================================================
// ===================================================
// MAIN MAP FUNCTION
// This is really the core function that builds everything:
// The Leaflet map, all markers, the detail panel that
// pops open when you click on a story site, and the 
// map reset when you close the panel
//
// Arguments:
//  - enhData: Enhancement sites metadata CSV
//  - recruitData: Recruitment data CSV
//  - timelineData: Enhancement timeline CSV
//  - {width}: the current container width which dynamically comes from resize()
// ===================================================
// ===================================================
function oysterMap(enhData, recruitData, timelineData, {width} = {}) {
    
    // -----------------------------------------------
    // BUILD THE CONTAINER DIVS
    // Three nested divs:
    //   - mainContainer: the outer wrapper (holds map + detail side by side)
    //      - mapContainer: the Leaflet map lives here
    //      - detailContainer: the site story panel (hidden until a site is clicked)
    // -----------------------------------------------

    // The outermost div
    // Width comes from resize() which passes the current pade width
    // so the map will fill the available space
    const mainContainer = document.createElement("div");
    mainContainer.className = "map-main-container";
    Object.assign(mainContainer.style, {
        width: `${width}px`,
        height: "90vh", // 90% of the browser window for height
        minHeight: "600px" // never shrink below 600px even on small screens
    });

    // The div for the Leaflet map
    // Starts at full width but shrinks to 40% when a story panel opens
    const mapContainer = document.createElement("div");
    mapContainer.className = "map-pane";
    Object.assign(mapContainer.style, {
        width: "100%",
        height: "100%",
        borderRadius: "8px",
        transition: "all 0.25s ease-in-out"  // smooth animation when width changes
    });

    // The story panel div, starts hidden (display: "none")
    // When a story site icon is clicked it displays ("flex")
    // There is a frozen button bar at the top and the rest scrolls vertically
    const detailContainer = document.createElement("div");
    detailContainer.className = "detail-pane";
    Object.assign(detailContainer.style, {
        display: "none",   // invisible until showDetail() is called
        width: "80%",   // takes 60% of mainContainer when visible
        height: "100%",
        backgroundColor: "white",
        borderRadius: "8px",
        transition: "all 1s ease-in-out",
        opacity: "0",   // starts transparent, fades in
        overflowY: "hidden",   // the container itself does NOT scroll only the scrollBody inside it does
        overflowX: "hidden",   // no horizontal scrolling
        boxSizing: "border-box",   // padding is included in the width/height calculation
        flexDirection: "column"   // when display becomes "flex", content stacks vertically
    });

    // Add both child divs into the main container 
    // appendChild() places an element inside another
    mainContainer.appendChild(mapContainer);
    mainContainer.appendChild(detailContainer);


    // -----------------------------------------------
    // INITIALISE THE LEAFLET MAP
    // L is the Leaflet library imported at the top of the code
    // L.map() takes a DOM element and an options object
    // center and zoom are also constants defined at the top!
    // -----------------------------------------------
    const map = L.map(mapContainer, { center, zoom });

    // Store the map container so the filter panel can access it later
    // _map means we are making it an internal property of the main container
    mainContainer._map = map;

    // Add the basemap layer
    // Using map imagery from CartoDB
    L.tileLayer('https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png', {
        attribution: '© OpenStreetMap © CartoDB', // Attribution required for free use
        maxZoom: 15
    }).addTo(map);


    // -----------------------------------------------
    // CREATE LAYER GROUPS
    // Layer groups let us show/hide all markers of a type at once
    // Both start added to the map by default
    // The filter panel checkboxes call .addTo(map) or .remove() on these layers !!
    // -----------------------------------------------
    const recruitmentLayer = L.layerGroup();
    const enhancementLayer = L.layerGroup().addTo(map);

    // Store markers by site name globally so they can be accessed by the filter panel
    window.markersBySite = {};

    // ===================================================
    // SHOW DETAIL PANEL
    // Called when the user clicks a story site marker.
    // Rearranges the layout so the map shrinks to 40% and
    // the story panel fills the remaining 60%.
    // ===================================================
    function showDetail(site) {
        // Record which site is currently open globally so other 
        // parts of the code can check which site is selected
        window.selectedSite = site.site_name;

        // Switch mainContainer from "block" layout (map full width)
        // to "flex" layout (two inner panels side by side)
        mainContainer.style.display = "flex";
        mainContainer.style.gap = "10px";   // small gap between map and story panel
        mainContainer.classList.add("detail-open");

        // Shrink the map to 40% width
        mapContainer.style.width = "30%";
        mapContainer.style.flexShrink = "0";   // don't let flex squish it any further

        // Show the detail panel as a flex column
        detailContainer.style.display = "flex";

        // Fade the panel in
        // 10ms delay makes sure display:flex is initiated before we try and animate
        setTimeout(() => detailContainer.style.opacity = "1", 10);

        // Wait for the map container's width transition to actually finish
        // before telling Leaflet to resize + recenter. Trying to fix weird centering issue
        const handleResize = (e) => {
            // Only react to the width transition, not other properties
            if (e.propertyName !== "width") return;
            mapContainer.removeEventListener("transitionend", handleResize);
            map.invalidateSize({ pan: false });
            map.setView(
                [site.latitude, site.longitude],
                13,
                { animate: false }
            );
        };
        mapContainer.addEventListener("transitionend", handleResize);

        // Fallback in case transitionend doesn't fire (e.g. width was
        // already 30% and no transition actually occurs)
        setTimeout(() => {
            mapContainer.removeEventListener("transitionend", handleResize);
            map.invalidateSize({ pan: false });
            map.setView(
                [site.latitude, site.longitude],
                13,
                { animate: false }
            );
        }, 300); // slightly longer than the 0.25s CSS transition

        // Clear any previously shown site content before building the new one
        detailContainer.innerHTML = "";

        // -----------------------------------------------
        // Zone 1: Back Button bar
        // Sits at the top of the detail panel & never scrolls out of view
        // flexShrink:"0" means flex will never compress this div
        // even if the content below needs more space! 
        // Let the user get out of there easy
        // -----------------------------------------------
        const buttonBar = document.createElement("div");
        Object.assign(buttonBar.style, {
            flexShrink: "0",
            padding: "16px 20px",
            borderBottom: "1px solid #e0e0e0",
            backgroundColor: "white",
            borderRadius: "8px 8px 0 0",  // only round the top two corners, the bottom edge butts against scrollBody
            zIndex: "10", // sit above scrolled content if it creeps up
            display: "flex", // side by side layout for title
            alignItems: "center",
            justifyContent: "space-between"
        });

        // Build the back button to return to the full map view, closing detail panel
        const backButton = document.createElement("button");
        backButton.textContent = "← Back to Map";
        Object.assign(backButton.style, {
            padding: "10px 20px",
            cursor: "pointer",
            border: "2px solid #045B4C",
            borderRadius: "6px",
            backgroundColor: "white",
            color: "#045B4C",
            fontSize: "14px",
            fontWeight: "600",
            transition: "all 0.2s ease",
            textTransform: "uppercase",
            letterSpacing: "0.5px"
        });

        // Hover effect!! swap background and text color when mouse goes over button
        // onmouseenter/onmouseleave are shorthand for addEventListener
        backButton.onmouseenter = () => {
            backButton.style.backgroundColor = "#045B4C";
            backButton.style.color = "white";
        };
        backButton.onmouseleave = () => {
            backButton.style.backgroundColor = "white";
            backButton.style.color = "#045B4C";
        };

        // Wire up the click to call resetView() (defined below)
        backButton.onclick = resetView;

        // Place the button inside the button bar div that doesn't scroll away
        buttonBar.appendChild(backButton);

        const siteTitle = document.createElement("h2");
        siteTitle.textContent = site.site_name;
        Object.assign(siteTitle.style, {
            margin: "0",
            fontSize: "28px",
            fontWeight: "700",
            color: "#045B4C",
            letterSpacing: "0.5px"
        });

        buttonBar.appendChild(siteTitle);

        // -----------------------------------------------
        // Zone 2: Scroll body
        // Fills all remaining height below the button bar
        // flexGrow:"1" means "take up all leftover space"
        // This is the story and graphs that you can scroll through
        // -----------------------------------------------
        const scrollBody = document.createElement("div");
        Object.assign(scrollBody.style, {
            flexGrow: "1",  // expand to fill remaining height after buttonBar
            overflowY: "auto",   // show scrollbar only when content is taller than the div
            overflowX: "hidden",    // no horizontal scrolling
            padding: "20px",
            boxSizing: "border-box"
        });

        // Add both zones into the detail container.
        // Order matters: buttonBar first = top, scrollBody second = below it.
        detailContainer.appendChild(buttonBar);
        detailContainer.appendChild(scrollBody);

        // Grab the site's content from the site panel builder and
        // place it in the scrollable area
        const sitePanel = buildSitePanel(site.site_name);
        scrollBody.appendChild(sitePanel);
    }

    // ===================================================
    // RESET VIEW
    // Called by the back button, essentially reverses everything 
    // showDetail() did:
    //      - fades out the panel
    //      - restores the map to full width
    //      - and resets the zoom to the default overview
    // ===================================================  
    function resetView() {

        // Clear the selected site record
        window.selectedSite = null;

        // Start the fade oout
        detailContainer.style.opacity = "0";

        // Wait a sec for the fade to finish before restructering layot
        setTimeout(() => {
            // Remove narrow-screen override class now — detail panel is
            // already invisible (opacity 0) so no visible jump occurs
            mainContainer.classList.remove("detail-open");

            mainContainer.style.display = "block";  // reset to a single column so the map is full width
            Object.assign(mapContainer.style, {
                width: "100%",
                height: "100%"
            });
            detailContainer.style.display = "none"; // hide the detail panel

            // Wait another sec for the layout shift to settle and
            // then tell Leaflet to recalculate size and set view
            setTimeout(() => {
                map.invalidateSize();
                map.setView(center, zoom, { animate : false });
            }, 250);
        }, 250);
    }


    // ===================================================
    // Build the recruitment circle marker layer.
    // createRecruitmentLayerManager() handles marker creation,
    // styling, and click actions
    // ===================================================
    const recruitLayerManager = createRecruitmentLayerManager(
        recruitData,
        recruitmentLayer,
        map,
        (station) => showRecruitmentDetail(
            station,
            recruitData,
            detailContainer,
            map,
            mainContainer,
            mapContainer,
            resetView
        )
    );
    recruitLayerManager.init();


    // ===================================================
    // ADD ENHANCEMENT MARKERS
    // Story sites get seperate styling
    // Story sites get a click handler that opens the detail panel!!
    // ===================================================
    enhData.forEach(site => {
        // Skip this row if coordinates are missing or invalid
        if(!site.latitude || !site.longitude ||
            site.latitude === 'NA' || site.longitude === 'NA' ||
            isNaN(parseFloat(site.latitude)) || isNaN(parseFloat(site.longitude))) return;

        // story_sites is the Set defined at the top of the file
        // .has() checks if site_name is in that Set
        const isStorySite = story_sites.has(site.site_name);

        // Pick different color for story sites
        // This is called a ternary: condition ? value_if_true : value_if_false
        const icon = isStorySite ? enhancementStoryIcon : enhancementIcon;

        const photoUrl = tooltipPhotos[site.site_name];

        // Create the marker with the right icon
        // By using an arrow function to build the tooltip, we allow
        // Leaflet to build it only when the tooltip is about to open
        // and not at the loading when the marker is created
        const marker = L.marker(
            [site.latitude, site.longitude],
            { icon: icon }
        )
        .bindTooltip(
            () => buildTooltipHTML(site, timelineData, isStorySite, photoUrl),
            {
                direction: 'auto',
                permanent: false,
                className: 'custom-tooltip'
            }
        )
        .addTo(enhancementLayer);

        // Only story sites get a click handler and a pointer cursor
        // Non story sites are visible on the map and show the tooltip
        // but clicking doesn't do anything
        if (isStorySite) {

            // marker.on() is Leaflet's version of addEventListener
            marker.on("click", () => showDetail(site));

            // getElement() returns the HTML element for this marker so we
            // can get the CSS cursor style that we create
            marker.on("mouseover", () => {
                marker.getElement().style.cursor = "pointer";
            });
        }

        // Store marker reference for the site selector dropdown
        window.markersBySite[site.site_name] = marker;
    });


    // ===================================================
    // ENHANCEMENT LEGEND
    // L.control() creates a Leaflet control
    // onAdd() is called by Leaflet when it's ready to place
    // the control; it must return a DOM element
    // ===================================================
    const legend = L.control({ position: 'topright' });  // Put it in the top right corner
    let enhancementLegend; // we'll store a reference so the filter panel can show/hide it

    legend.onAdd = function() {
        const div = L.DomUtil.create('div', 'map-legend');
        div.innerHTML = `
            <div class="map-legend-box">
                <div class="map-legend-header">
                    <span>Site Types</span>
                    <button class="legend-toggle-btn" type="button" aria-label="Toggle legend">−</button>
                </div>
                <div class="map-legend-body">
                    <div class="map-legend-row">
                        <span class="map-legend-swatch" style="background-color: var(--marker-standard);"></span>
                        Enhancement Site
                    </div>
                    <div class="map-legend-row">
                        <span class="map-legend-swatch" style="background-color: var(--marker-story);"></span>
                        Enhancement Story - Click to learn more
                    </div>
                </div>
            </div>
        `;

        const box = div.querySelector('.map-legend-box');
        const toggleBtn = div.querySelector('.legend-toggle-btn');
        toggleBtn.addEventListener('click', (e) => {
            e.stopPropagation();
            box.classList.toggle('collapsed');
            toggleBtn.textContent = box.classList.contains('collapsed') ? '+' : '−';
        });

        L.DomEvent.disableClickPropagation(div); // stop taps on the button/box reaching the map
        return div;
    };

    enhancementLegend = legend;
    legend.addTo(map);

    // Add scale bar
    L.control.scale({ imperial: true, metric: true }).addTo(map);

    // -----------------------------------------------
    // RESET VIEW BUTTON on map
    // Returns map to default center + zoom
    // -----------------------------------------------
    const resetBtn = L.control({ position: "topleft" });
    resetBtn.onAdd = function() {
        const btn = L.DomUtil.create("button", "leaflet-reset-btn");
        btn.title = "Reset zoom level";
        btn.innerHTML = `<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" 
            viewBox="0 0 24 24" fill="none" stroke="currentColor" 
            stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M3 3h6M3 3v6M21 3h-6M21 3v6M3 21h6M3 21v-6M21 21h-6M21 21v-6"/>
        </svg>`;
        Object.assign(btn.style, {
            background: "white",
            border: "2px solid rgba(0,0,0,0.2)",
            borderRadius: "4px",
            width: "32px",
            height: "32px",
            cursor: "pointer",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            color: "#333",
            padding: "0"
        });
        btn.onclick = () => map.setView(center, zoom, { animate: true });
        // Prevent map clicks from firing when clicking button
        L.DomEvent.disableClickPropagation(btn);
        return btn;
    };
    resetBtn.addTo(map);

    // When the browser window is resized, tell Leaflet to
    // recalculate the map's pixel dimensions after 100ms
    // The delay prevents it running dozens of times during a drag resize!
    window.addEventListener('resize', () => setTimeout(() => map.invalidateSize(), 100));

    // Also invalidate once immediately on load, in case the map
    // renders before its container has fully settled to its final size
    // Fix weird loading
    setTimeout(() => map.invalidateSize(), 100);

    // Store the layer groups on the container so createFilterPanel()
    // can access them after the map is built
    mainContainer._enhancementLayer = enhancementLayer;
    mainContainer._recruitmentLayer = recruitmentLayer;
    mainContainer._recruitLayerManager = recruitLayerManager;
    mainContainer._enhancementLegend = enhancementLegend;
    mainContainer._resetView = resetView;  // expose so filter panel can call it from outside

    // Return the whole assembled container div
    return mainContainer;
} // END MAIN MAP FUNCTION


// ===================================================
// INSTANTIATE MAP
// Build once, place in a persistent div, use
// ResizeObserver to keep width in sync without
// ever rebuilding the map or touching its DOM.
// ===================================================

// Wait for the placeholder card to exist in the DOM
setTimeout(() => {
    const placeholder = document.querySelector('#map-card-placeholder');
    if (!placeholder) return;

    // Build the map once at the placeholder's actual current width
    const initialWidth = placeholder.offsetWidth || 800;
    const container = oysterMap(
        enh_sites_metadata,
        recruitment_data,
        timeline_data,
        { width: initialWidth }
    );
    window.currentMapInstance = container;

    // Place the map inside the placeholder card — it stays here forever
    placeholder.appendChild(container);

    // Build the filter panel once
    setTimeout(() => {
        const filterContainer = document.querySelector('#filter-container');
        if (filterContainer && container._enhancementLayer) {
            filterContainer.innerHTML = '';
            filterContainer.appendChild(
                createFilterPanel(
                    container._enhancementLayer,
                    container._recruitmentLayer,
                    container._map,
                    enh_sites_metadata,
                    recruitment_data,                   // full recruitment CSV
                    container._recruitLayerManager,  // layer manager with years + updateYear()
                    container._enhancementLegend,    // legend ref so tabs can swap it
                    () => { if (window.currentMapInstance?._resetView) window.currentMapInstance._resetView(); }
                )
            );
        }
    }, 100);

    // Watch the placeholder for size changes using ResizeObserver.
    // This fires when the card changes width — e.g. on window resize.
    // We just update the container width and tell Leaflet to redraw.
    const observer = new ResizeObserver(entries => {
        for (const entry of entries) {
            const newWidth = entry.contentRect.width;
            if (window.currentMapInstance) {
                window.currentMapInstance.style.width = `${newWidth}px`;
                window.currentMapInstance._map.invalidateSize();
            }
        }
    });

    // Start watching the placeholder card
    observer.observe(placeholder);

}, 200); // 200ms delay to ensure the DOM has rendered the card
```

<!-- Leaflet CSS -->
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/leaflet@1.9.4/dist/leaflet.css" />

<!-- =================================================== -->
<!-- CSS STYLES -->
<!-- =================================================== -->
<style>

    /* ==================================================
        GLOBAL LAYOUT
        Overall page structure and spacing
        ================================================== */

        /* ---------- Branding ---------- */
        :root {
            --brand-teal: #045B4C;
            --brand-teal-light: #5B9E91;
            --marker-standard: #8B635C;
            --marker-story: #3d9e06; 
            --marker-stroke: #FFFFFF;
            --recruit-no-data: #c8c8c8;
}

        /* ---------- Header ---------- */

        #observablehq-header {
            position: absolute;
            background-color: #045B4C;
            height: 150px;
            align-items: center;
            padding: 0 30px;
        }

        /* For using photo as header background */
         /* #observablehq-header {
            position: absolute;
            background-size: cover;
            background-position: center;
            height: 150px;
            align-items: center;
            padding: 0 30px;
        } */

        /* ---------- Body ---------- */
        /* Adds spacing so page content sits below the fixed header
        and doesn't touch the browser edges. */

        body {
            padding-top: 80px;
            padding-left: 40px;
            padding-right: 40px;
        }

        /* ---------- Footer ---------- */

        #observablehq-footer {
            position: absolute;
            margin-top: 0 !important;
            padding-top: 30px;
            background-color: #5A5A5A;
            align-items: center;
            width: 100%;
            left: 0;
            padding: 0 30px;
            box-sizing: border-box;
        }

    /* ==================================================
        FLASH CARDS
        Displayed above the dashboard
        ================================================== */

        /* ---------- Grid Layout ---------- */

        .stats-grid {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 1rem;
            text-align: center;
        }

        .stats-grid > * {
            min-width: 0;
        }

        /* ---------- Individual Cards ---------- */

        .stats-grid .card {
            padding: 12px 8px;
            overflow: hidden;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
        }

        /* ---------- Large Text ---------- */

        .stats-grid .big {
            display: -webkit-box;
            -webkit-box-orient: vertical;
            -webkit-line-clamp: 2;

            overflow: hidden;
            text-overflow: ellipsis;
        }


        .stats-grid h1.muted {
            display: -webkit-box;
            -webkit-box-orient: vertical;
            -webkit-line-clamp: 2;

            overflow: hidden;
            text-overflow: ellipsis;

            margin: 0 0 4px 0;
        }

     /* ==================================================
        INTRO HERO
        Landing section introducing the dashboard and
        explaining the two map modes.
        ================================================== */

        /* ---------- Hero Container ---------- */

        #intro-hero {
            background-size: cover;
            background-position: center;
            color: white;
            border: 2px solid #000;
        }

        /* ---------- Intro Layout ---------- */

        .intro-hero-grid {
            display: grid;
            grid-template-columns: 1.3fr 1fr;
            gap: 1.5rem;
            align-items: start;
        }

        .intro-hero-grid > * {
            min-width: 0;
        }

        @media (max-width: 700px) {
            .intro-hero-grid {
                grid-template-columns: 1fr;
            }
         }

        /* ---------- Intro Text Panel ---------- */

        .intro-panel {
            background: rgba(255,255,255,0.8);
            border-radius: 10px;
            padding: 24px;
            box-shadow: 0 2px 12px rgba(0,0,0,0.12);
        }

        /* ---------- Callout Cards ---------- */

        .intro-card {
            padding: 20px;
            border-radius: 10px;
            font-size: 13px;
            line-height: 1.7;
            color: #333;
            box-shadow: 0 2px 12px rgba(0,0,0,0.12);
        }

        .intro-card p {
            margin: 0;
        }

        .intro-card--enhancement {
            border-left: 4px solid #045B4C;
            background: rgba(255,255,255,0.8);
        }

        .intro-card--recruitment {
            border-left: 4px solid #045B4C;
            background: rgba(255,255,255,0.8);
        }

        /* ---------- Card Labels ---------- */

        .intro-card-label {
            font-size: 12px;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            margin-bottom: 8px;
        }

        /* ---------- Tip Banner ---------- */

        .intro-tip {
            margin-top: 1.5rem;
            padding: 14px 18px;
            background: rgba(234,243,241,0.92);
            border-radius: 10px;
            font-size: 13px;
            line-height: 1.7;
            color: #333;
            box-shadow: 0 2px 12px rgba(0,0,0,0.12);
            display: flex;
            align-items: center;
            gap: 14px;
        }

        .intro-tip-icon {
            font-size: 30px;
            line-height: 1;
            flex-shrink: 0;
        }

        .intro-tip-text {
            flex: 1;
        }

    /* ==================================================
        DASHBOARD LAYOUT
        Primary page content containing the filter panel,
        map, and detail panel.
        ================================================== */

        /* ---------- Dashboard Grid ---------- */

        .dashboard-grid {
            display: grid;
            grid-template-columns: minmax(160px,1fr) 3fr; /* filter : map roughly 1:3 */
            gap: 1rem;
            align-items: start;
        }

        .dashboard-grid > * {
            min-width: 0;
        }

        /* ---------- Active Tab Visibility ---------- */

        .filter-tab-content.hidden {
            display: none;
        }

    /* ==================================================
        LEAFLET MAP
        Shared styling for the interactive map, controls,
        legends, and tooltips.
        ================================================== */

        /* Use the page font inside Leaflet controls */
        .leaflet-container {
            font-family: inherit;
        }

        /* ---------- Attribution ---------- */

        .leaflet-control-attribution {
            background-color: rgba(255,255,255,0.7);
            font-size: 10px;
            opacity: 0.6;
            padding: 2px 5px;
        }

        .leaflet-control-attribution:hover {
            opacity: 1;
        }

        /* ---------- Reset View Button ---------- */

        .leaflet-reset-btn:hover {
            background: #f4f4f4 !important;
        }

        /* Dark mode styling */
        @media (prefers-color-scheme: dark) {

            .leaflet-reset-btn {
                background: #222 !important;
                color: #e0e0e0 !important;
                border-color: rgba(255,255,255,0.3) !important;
            }

        }

        /* ---------- Recruitment Legend ---------- */
            /* Prevent legend from blocking map interaction. */

        /* ---------- Map Legends (shared box for enhancement + recruitment) ---------- */

        .map-legend-box {
            background: white;
            padding: 12px;
            border-radius: 8px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.15);
            font-size: 13px;
            max-width: 220px;
            box-sizing: border-box;
            pointer-events: auto; /* legend itself stays clickable even though the wrapper below is not */
        }

        .recruit-legend-box {
            min-width: 170px;
            font-size: 12px;
            padding: 14px;
        }

        .map-legend-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            font-weight: 700;
            color: #045B4C;
            font-size: 11px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            margin-bottom: 8px;
        }

        .map-legend-box.collapsed .map-legend-header {
            margin-bottom: 0;
        }

        .legend-toggle-btn {
            border: none;
            background: none;
            color: #045B4C;
            font-size: 16px;
            line-height: 1;
            cursor: pointer;
            padding: 0 0 0 10px;
            flex-shrink: 0;
        }

        .map-legend-row {
            display: flex;
            align-items: center;
            gap: 8px;
            margin: 5px 0;
            color: #555;
        }

        .map-legend-swatch {
            width: 14px;
            height: 14px;
            border-radius: 50%;
            border: 2px solid var(--marker-stroke, #fff);
            flex-shrink: 0;
        }

        .recruit-legend-box .map-legend-swatch {
            border: 1.5px solid rgba(0,0,0,0.15);
        }

        .map-legend-box.collapsed .map-legend-body {
            display: none;
        }

        /* Leaflet control wrapper stays click-through outside the box;
        .map-legend-box above re-enables pointer events for its own content */
        .map-legend,
        .recruit-legend {
            pointer-events: none;
        }

        /* Hide legends whenever a detail panel is open. */

        .map-main-container.detail-open .map-legend,
        .map-main-container.detail-open .recruit-legend {
            display: none !important;
        }

        /* ---------- Custom Tooltips ---------- */

        .custom-tooltip {
            padding: 0 !important;
            box-shadow: 0 2px 8px rgba(0,0,0,0.15);
            overflow: hidden;
            border-radius: 8px;
        }

        .custom-tooltip .leaflet-tooltip-content {
            padding: 0 !important;
            margin: 0;
        }

        .custom-tooltip img {
            display: block;
            background: #f0f0f0;
        }

    /* ==================================================
        FILTER PANEL
        Controls used to navigate enhancement sites
        and recruitment monitoring stations.
        ================================================== */

        /* ---------- Tab Buttons ---------- */

        .filter-tab-btn {
            flex: 1;
            padding: 9px 10px;
            border: 2px solid #045B4C;
            border-radius: 6px;
            background: white;
            color: #045B4C;
            font-size: 12px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.2s ease;
            text-transform: uppercase;
            letter-spacing: 0.4px;
        }

        .filter-tab-btn.active {
            background: #045B4C;
            color: white;
        }

        /* ---------- Dropdowns ---------- */

        .filter-select {
            width: 100%;
            padding: 10px 12px;
            border: 2px solid #e0e0e0;
            border-radius: 6px;
            background: white;
            color: #333;
            font-size: 14px;
            cursor: pointer;
            transition: border-color 0.2s ease,
                        box-shadow 0.2s ease;
        }

        .filter-select:focus {
            border-color: #045B4C;
            box-shadow: 0 0 0 3px rgba(4,91,76,0.1);
            outline: none;
        }

        /* ---------- Toggle Buttons ---------- */

        .type-toggle-btn {
            padding: 8px 16px;
            border: 2px solid #045B4C;
            border-radius: 20px;
            background: #045B4C;
            color: white;
            font-size: 13px;
            font-weight: 500;
            cursor: pointer;
            white-space: nowrap;
            transition: all 0.2s ease;
        }

        .type-toggle-btn.inactive {
            background: white;
            color: #045B4C;
        }

        .type-toggle-btn.inactive:hover {
            background: #e8f4f2;
        }

        .type-toggle-btn:not(.inactive):hover {
            background: #034a3e;
        }

        .type-toggle-btn:not(.inactive)::before {
            content: "✓";
            margin-right: 6px;
            font-weight: bold;
        }

        .type-toggle-btn.inactive::before {
            content: "";
        }

        /* ---------- Year Slider ---------- */

        input[type="range"] {
            -webkit-appearance: none;
            height: 4px;
            border-radius: 2px;
            background: #d0e8e4;
            outline: none;
        }

        input[type="range"]::-webkit-slider-thumb {
            -webkit-appearance: none;
            width: 18px;
            height: 18px;
            border-radius: 50%;
            background: #045B4C;
            cursor: pointer;
            border: 2px solid white;
            box-shadow: 0 1px 4px rgba(0,0,0,0.2);
        }

        input[type="range"]::-moz-range-thumb {
            width: 18px;
            height: 18px;
            border-radius: 50%;
            background: #045B4C;
            cursor: pointer;
            border: 2px solid white;
            box-shadow: 0 1px 4px rgba(0,0,0,0.2);
        }

        /* ---------- Labels ---------- */

        .filter-section-label {
            display: block;
            margin-bottom: 8px;
            color: #045B4C;
            font-size: 13px;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }

        /* ---------- Layout ---------- */

        .filter-section {
            margin-bottom: 24px;
        }

        .filter-divider {
            height: 1px;
            margin: 24px 0;
            background: linear-gradient(
                to right,
                transparent,
                #ddd,
                transparent
            );
        }

        /* ---------- Helper Text ---------- */

        .filter-hint {
            margin-top: 6px;
            color: #666;
            font-size: 11px;
            font-style: italic;
        }

        .filter-click-hint {
            padding: 10px 12px;
            background: #f8f9fa;
            border-radius: 6px;
            color: #666;
            font-size: 12px;
            font-style: italic;
        }

        
    /* ==================================================
        PHOTO CAROUSEL
        Image carousel used throughout restoration
        story panels.
        ================================================== */

        .carousel {
            position: relative;
            width: 92%;
            margin: 0 auto 32px auto;
            background: transparent;
            border-radius: 12px;
            overflow: hidden;
            box-shadow: 0 4px 20px rgba(0,0,0,0.15);
        }

        /* ---------- Image Container ---------- */

        .carousel-images {
            position: relative;
            width: 100%;
            padding-bottom: 65%;
        }

        /* ---------- Slide Wrapper (image + caption) ---------- */

        .carousel-slide {
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            opacity: 0;
            transition: opacity 0.3s ease;
            pointer-events: none;
        }

        .carousel-slide.active {
            opacity: 1;
            pointer-events: auto;
        }

        .carousel-image {
            width: 100%;
            height: 100%;
            object-fit: cover;
            display: block;
            background: transparent;
            border-radius: 12px;
        }

        /* ---------- Caption ---------- */

        .carousel-caption {
            position: absolute;
            bottom: 0;
            left: 0;
            right: 0;
            padding: 28px 16px 34px 16px; /* extra bottom padding clears the dots */
            background: linear-gradient(to top, rgba(0,0,0,0.65), transparent);
            color: white;
            font-size: 13px;
            line-height: 1.5;
            text-shadow: 0 1px 3px rgba(0,0,0,0.4);

            /* Hover-to-reveal */
            opacity: 0;
            transition: opacity 0.25s ease;
        }

        .carousel-slide:hover .carousel-caption {
            opacity: 1;
        }

        /* ---------- Navigation Buttons ---------- */

        .carousel-btn {
            position: absolute;
            top: 50%;
            transform: translateY(-50%);
            width: 36px;
            height: 36px;
            display: flex;
            align-items: center;
            justify-content: center;
            background: rgba(0,0,0,0.35);
            color: white;
            border: none;
            border-radius: 50%;
            font-size: 28px;
            cursor: pointer;
            z-index: 10;
            transition: background 0.2s ease;
        }

        .carousel-btn:hover {
            background: rgba(0,0,0,0.6);
        }

        .carousel-btn.prev {
            left: 12px;
        }

        .carousel-btn.next {
            right: 12px;
        }

        /* ---------- Page Dots ---------- */

        .carousel-dots {
            position: absolute;
            bottom: 10px;
            left: 50%;
            transform: translateX(-50%);

            display: flex;
            gap: 8px;

            z-index: 10;
        }

        .carousel-dot {
            width: 8px;
            height: 8px;

            border-radius: 50%;
            background: rgba(255,255,255,0.5);

            cursor: pointer;
            transition: background 0.2s ease;
        }

        .carousel-dot.active {
            background: rgba(255,255,255,1);
        }

        .carousel-dot:hover {
            background: rgba(255,255,255,0.8);
        }

    /* ==================================================
        RESPONSIVE LAYOUT
        Screen-size adjustments for tablets and phones.
        ================================================== */

        /* -----------------------------------------------
            Smaller desktop
            Detail panel expands when open
        ----------------------------------------------- */

        @media (max-width: 1100px) {

            .map-main-container.detail-open {
                gap: 0 !important;
            }

            .map-main-container.detail-open .map-pane {
                width: 0 !important;
                flex-shrink: 0 !important;
                overflow: hidden !important;
            }

            .map-main-container.detail-open .detail-pane {
                width: 100% !important;
            }
        }


        /* -----------------------------------------------
            Tablet layout
            Stack filter panel above map
            Convert filter controls to wrapping row
        ----------------------------------------------- */

        @media (max-width: 900px) {

            .dashboard-grid {
                grid-template-columns: 1fr;
            }


            .filter-tab-content:not(.hidden) {
                display: flex !important;
                flex-wrap: wrap;
                gap: 20px;
                align-items: flex-start;
            }


            .filter-section {
                flex: 1 1 220px;
                margin-bottom: 0 !important;
            }


            .filter-divider {
                display: none;
            }
        }


        /* -----------------------------------------------
            Small tablet
            Collapse statistics cards
        ----------------------------------------------- */

        @media (max-width: 800px) {

            .stats-grid {
                grid-template-columns: repeat(2, 1fr);
            }
        }


        /* -----------------------------------------------
            Mobile layout MORE WORK HERE NEEDED
        ----------------------------------------------- */

        /* Stack intro cards vertically */
        @media (max-width: 700px) {

            .map-legend-box {
                max-width: 150px;
                font-size: 11px;
                padding: 8px 10px;
            }

            .recruit-legend-box {
                min-width: 0;
            }

            .map-legend-swatch {
                width: 11px;
                height: 11px;
            }

            .intro-cards { 
                grid-template-columns: 1fr; 
            }
        }

        /* Shrink built-in Observable card padding */

        @media (max-width: 600px) {


            #observablehq-center {
                margin: 6px;
            }

            /* Reduce body padding on the sides */
            body {
                padding-left: 4px;
                padding-right: 4px;
            }

            /* Reduce Observable's built-in card padding */
            .card {
                padding: 12px !important;
            }

            /* Tighten the gap between filter panel and map */
            .dashboard-grid {
                gap: 4px;
            }

            /* Tighten the intro hero panel padding too, if it's also cramped */
            #intro-hero {
                padding: 0.5rem;
            }

            .intro-panel {
                padding: 10px;
            }

            .intro-card {
                padding: 12px;
            }
        }

</style>


<!-- Display everything in cards on the page -->
<!-- Map card div lives here permanently, outside Observable's control to fix wonkyness with resizing -->
<div id="persistent-map-card" style="grid-column: span 3;"></div>

<div class="dashboard-grid">
  <div class="card">
    ${(function() {
      const div = document.createElement('div');
      div.id = 'filter-container';
      return div;
    })()}
  </div>
  <div class="card" id="map-card-placeholder"></div>
</div>