---
toc: false
title: "Reorganized"
theme: dashboard
header: "<a href='https://restorationfund.org'><img src='data/images/logo-transwhite.png' alt='Logo' style='height: 120px;'></a>"
pager: false
---

<!-- =================================================== -->
<!-- Header & footer syling -->
<!-- =================================================== -->
<style>
  /* Header */
  #observablehq-header {
    position: absolute;
    background-color: #045B4C;
    height: 150px;
    align-items: center;
    padding: 0 30px;
  }

  /* Space below header so page content doesn't overlap */
  body {
    padding-top: 80px;
    padding-left: 40px;
    padding-right:40px;
  }

/* Footer */
  #observablehq-footer {
    position: absolute;
    background-color: #5A5A5A;
    align-items: center;
    width: 100%;
    left: 0;
    padding: 0 30px;
    box-sizing: border-box;
  }
</style>
<!-- =================================================== -->
<!-- END Header & footer syling -->
<!-- =================================================== -->

<!-- =================================================== -->
<!-- Cards with flashy facts -->
<!-- =================================================== -->
<div class="grid grid-cols-4" style="text-align: center;">
  <div class="card">
    <h1 class="muted">Acres Restored</h1>
    <span class="big" style="color: #045B4C">141.3</span>
  </div>
  <div class="card" style="text-align: center;">
    <h1 class="muted">Sites Visited</h1>
    <span class="big" style="color: #045B4C">777</span>
  </div>
  <div class="card" style="text-align: center;">
    <h1 class="muted">Some Other</h1>
    <span class="big" style="color: #045B4C">222</span>
  </div>
  <div class="card" style="text-align: center;">
    <h1 class="muted">Catchy Facts</h1>
    <span class="big" style="color: #045B4C">999</span>
  </div>
</div>
<!-- =================================================== -->
<!-- END Cards with flashy facts -->
<!-- =================================================== -->

---

```js
// ===================================================
// LOAD DATA
// ===================================================

// Enhancement sites metadata for map points and tooltips
const enh_sites_metadata = await FileAttachment("data/enhancement_sites_metadata.csv").csv({typed: true});

// Recruitment sites for map points
const recruit_sites = await FileAttachment("data/recruitment_station_info.csv").csv({typed: true});

// Oly assessment data. MIGHT CHANGE IF DATA BECOMES SITE SPECIFIC
const ann_densities = await FileAttachment("data/assessments.csv").csv({typed: true});

// Data for timeline
const timeline_data = await FileAttachment("data/timeline_data.csv").csv({typed: true});

// Fidalgo Bay population estimates
const fidalgo_pop_est = await FileAttachment("data/fidalgo_population_estimates.csv").csv({typed: true});

// Fidalgo Bay shell height
const fidalgo_heights = await FileAttachment("data/fidalgo_heights_2023.csv").csv({typed: true});

// ===================================================
// IMPORT LIBRARIES
// ===================================================
import * as L from "npm:leaflet@1.9.4";

// ===================================================
// SET GLOBAL STATES
// ===================================================
window.highlightedLocation = null;
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
//   "Silverdale",
//   "Chico Bay",
//   "Oyster Bay"
  // Add more here as stories are written
]);

// ===================================================
// TOOLTIP PHOTOS
// ===================================================
const tooltipPhotos = {
  "Port Gamble Bay":  FileAttachment("data/images/port_gamble_SAMPLE_tooltip.jpg").href,
  "Quilcene Bay":     FileAttachment("data/images/quilcene_SAMPLE_tooltip.jpg").href,
  "Sinclair Inlet":   FileAttachment("data/images/sinclair_SAMPLE_tooltip.jpg").href,
  "Legion Park":      FileAttachment("data/images/legion_SAMPLE_tooltip.jpg").href,
  "Fidalgo Bay":      FileAttachment("data/images/fidalgo_tooltip.jpeg").href
  // Add more here
};

// ===================================================
// ===================================================
// MAP ICONS
// - Enhancement sites
// - Enhancement sites with stories
// - Recruitment stations
// ===================================================
// ===================================================

// --- Enhancement: standard (blue circle) ---
const enhancementIcon = L.divIcon({
  className: '',  // empty so Leaflet doesn't add default styles
  html: `<div style="
    background-color: #4e79a7;
    width: 14px;
    height: 14px;
    border-radius: 50%;
    border: 2px solid white;
    box-shadow: 0 0 4px #939393;
  "></div>`,
  iconSize: [18, 18],
  iconAnchor: [9, 9]
});

// --- Enhancement: story site (star) ---
// Distinguishing visually sites with stories
const enhancementStoryIcon = L.divIcon({
  className: '',
  html: `
    <div style="position: relative; width: 18px; height: 18px;">
      <!-- Pulse ring — animates once on load then disappears -->
      <div class="story-pulse-ring"></div>
      <!-- Circle -->
      <div style="
        background-color: #4e79a7;
        width: 14px;
        height: 14px;
        border-radius: 50%;
        border: 2px solid white;
        box-shadow: 0 0 4px #939393;
      "></div>
    </div>`,
  iconSize: [18, 18],
  iconAnchor: [9, 9]
});

// --- Recruitment (red triangle) ---
const recruitmentIcon = L.divIcon({
  className: '',
  html: `<div style="
    width: 0;
    height: 0;
    border-left: 8px solid transparent;
    border-right: 8px solid transparent;
    border-bottom: 14px solid #e15759;
    filter: drop-shadow(0 0 3px rgba(0,0,0,0.4));
  "></div>`,
  iconSize: [16, 16],
  iconAnchor: [8, 14]
});

// ===================================================
// ===================================================
// SHARED FUNCTION: CAROUSEL
// Used by every site panel that has photos
// Pass the container div and an array of image URLs
// Creates scroll buttons and dots for photo count
// ===================================================
// ===================================================
function buildCarousel(container, photos) {
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
                  `<img src="${url}" class="carousel-image ${i === 0 ? 'active' : ''}">`
                // Stitch all the generated <img> strings together
                ).join('')}
            </div>

            <!-- Next photo button -->
            <button class="carousel-btn next">›</button>

            <div class="carousel-dots"></div>
         </div>
    `;
    // Find all <img> elements inside this container that have the class "carousel-image"
    const images = container.querySelectorAll('.carousel-image');

    const dotsContainer = container.querySelector('.carousel-dots');

    // Track which image is currently showing. Starts at 0 (the first image)
    let currentIndex = 0;

    // Loop over each image by its index to create one dot per photo
    images.forEach((_, i) => {
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
        images[currentIndex].classList.remove('active');

        // Also remove active from currently lit up dot
        dots[currentIndex].classList.remove('active');

        // Update currentIndex to the new image we want to show
        currentIndex = index;

        // Add active class to the new image
        images[currentIndex].classList.add('active');

        // Also add active class to the new dot
        dots[currentIndex].classList.add('active');
    }

    // Wire up the prev button (.onclick sets what happens when it's clicked)
    container.querySelector('.prev').onclick = () => {
        // Wraps around, so if we are on 0 and go back it will go to the last image
        showImage((currentIndex - 1 + images.length) % images.length);
    };

    // Wire up the next button
    container.querySelector('.next').onclick = () => {
        showImage((currentIndex + 1) % images.length);
    };
} // END CAROUSEL BUILDER FUNCTION


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
// SHARED FUNCTION: ENHANCEMENT TIMELINE
// TBD if this will be used - needs to be workshopped
// ===================================================
// ===================================================
function createEnhancementTimeline(data, selectedSite) {

    // Filter data to the selected site
    const siteData = data.filter(d => d.site_name === selectedSite);

    // Return an empty div if there is no data
    if (siteData.length === 0) {
        return document.createElement('div');
    }

    // Calculate number of lines and assign variable tick heights
    const preparedData = siteData.map((d, i) => {
        const text = d.timeline_text || '';
        const numberOfLines = Math.ceil(text.length / 30);
        // Variable tick heights to create vertical separation
        const tickPattern = [50, 80, 110];
        const tickHeight = tickPattern[i % 3];
        
        return {
        ...d,
        numberOfLines: Math.max(numberOfLines, 1),
        tickHeight: tickHeight
        };
    });

    // Calculate height dynamically
    const maxLines = Math.max(...preparedData.map(d => d.numberOfLines));
    const maxTick = Math.max(...preparedData.map(d => d.tickHeight));
    const height = Math.max(300, maxLines * 16 + maxTick * 2 + 20);

    return Plot.plot({
        style: {
            fontSize: "16px",
            fontFamily: "inherit"
        },
        height,
        marginLeft: 50,
        marginRight: 50,
        marginTop: 10,
        marginBottom: 10,
        x: {axis: null},
        y: { axis: null, domain: [-height / 2, height / 2] },
        marks: [
            // Horizontal timeline line
            Plot.ruleY([0], { stroke: "#045B4C", strokeWidth: 2 }),
            
            // Vertical tick marks with variable lengths
            Plot.ruleX(preparedData, {
                x: "year",
                y1: 0,
                y2: (d, i) => (i % 2 === 0 ? d.tickHeight : -d.tickHeight),
                stroke: "#045B4C",
                strokeWidth: 2.5
            }),
            // Dots at each year
            Plot.dot(preparedData, { 
                x: "year", 
                fill: "#fff", 
                stroke: "#045B4C",
                strokeWidth: 2,
                r: 5
            }),
            
            // Year labels (alternate above/below opposite to text)
            Plot.text(preparedData, {
                x: "year",
                y: (d, i) => (i % 2 === 0 ? -18 : 18),
                text: (d) => d.year.toString(),
                fill: "#045B4C",
                fontWeight: "bold",
                fontSize: 14
            }),
            
            // Timeline text descriptions
            Plot.text(preparedData, {
                x: "year",
                y: (d, i) =>
                i % 2 === 0
                    ? d.tickHeight + d.numberOfLines * 13 + 5
                    : -d.tickHeight - d.numberOfLines * 13 - 5,
                text: "label",
                fill: "#333",
                lineWidth: 12,
                fontSize: 14,
                textAnchor: "middle"
            }),

            // Tooltip on the dots showing the full description
            Plot.tip(preparedData, Plot.pointer({
                x: "year",
                y: (d, i) => i % 2 === 0
                    ? (d.tickHeight + d.numberOfLines * 13 + 5) / 2   // midpoint of above-line events
                    : -(d.tickHeight + d.numberOfLines * 13 + 5) / 2, // midpoint of below-line events
                title: d => `${d.year}: ${d.label}\n${'─'.repeat(20)}\n${d.description}`,
              //  fill: "white",
                stroke: "#e0e0e0",
                strokeWidth: 1,
                padding: 12,
                textPadding: 8,
                lineHeight: 1.2,
                fontSize: 14, 
                fontFamily: "inherit",
                maxWidth: 140,        // wraps text at 240px — key for readability
            }))
        ]
    });
} // END TIMELINE BUILDER FUNCTION

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
    // case "Silverdale":   return buildSilverdalePanel();
    // case "Chico Bay":    return buildChicoBayPanel();
    // case "Oyster Bay":   return buildOysterBayPanel();
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
        intro: `White clouds rise from grey smokestacks, blurring a sprawling refinery into the distant silhouette of Koma Kulshan. A retired railroad trestle cuts across the bay like an old scar. Human ambition is written plainly on the shoreline, and yet, millions of Olympia oysters tell a remarkable success story.`,

        context: `The story of Fidalgo Bay begins with a rumor: that Olympia oysters once resided in these shallow waters. By the early 2000s, none remained, but the bay’s protected shorelines and limited predators made it an ideal candidate for restoration. In 2002, alongside a strong network of partners, we spread Pacific oyster shell covered in Olympia oyster seed beside the old trestle on the eastern shore, marking the first Olympia oyster restoration effort in northern Puget Sound.`,

        ourWork: `What followed was a years-long conversation with the bay. Additional seeded cultch were added in subsequent years. Non-seed bearing Pacific oyster shell was introduced in 2006, 2008, and 2013 to enhance the substrate and expand the area available for larval settlement. When monitoring revealed that nearly all natural recruitment was concentrated on the eastern side, likely shaped by summer current patterns, we responded by seeding the west side of the bay in 2016. In 2018, two new half-acre plots of bulk Pacific shell were added, one on each side of the bay, and the west side was seeded once more months later to give larval abundance a fresh boost.`,

        dataCallout: `Since 2002, the estimated Olympia oyster population in Fidalgo Bay has grown from roughly 50,000 to over 5.5 million - a more than hundredfold increase over two decades.`,

        impact: `Growth through the 2000s and early 2010s was steady, from the initial 50,000 seeded individuals to 240,000 by 2013. Then, something shifted. The population began to accelerate, explosive growth driven no longer by our additions, but by the Olys themselves! The last 5 years alone saw numbers nearly double, from 2.9 million in 2018 to 5.5 million in 2023.`,

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

         <!-- Enhancement timeline -->
        <div style="
        background: white; padding: 24px; border-radius: 8px;
        box-shadow: 0 2px 8px rgba(0,0,0,0.08); margin-bottom: 40px;
        ">
        <h3 style="
            font-size: 16px; font-weight: 700; color: #045B4C;
            margin: 0 0 8px 0; text-transform: uppercase; letter-spacing: 0.5px;
        ">Enhancement History</h3>
        <p style="font-size: 14px; color: #666; margin: 0 0 20px 0; font-style: italic;">
            Timeline of restoration actions
        </p>
        <div id="fidalgo-timeline"></div>
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

        <!-- Population density plot -->
        <div style="
        background: white; padding: 24px; border-radius: 8px;
        box-shadow: 0 2px 8px rgba(0,0,0,0.08); margin-bottom: 40px;
        ">
        <h3 style="
            font-size: 16px; font-weight: 700; color: #045B4C;
            margin: 0 0 8px 0; text-transform: uppercase; letter-spacing: 0.5px;
        ">Population Size Over Time</h3>
        <p style="font-size: 14px; color: #666; margin: 0 0 20px 0; font-style: italic;">
            Estimated population size at Fidalgo Bay, 2001 to 2023
        </p>
        <div id="fidalgo-population-plot"></div>
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
        // Add more photos in like this once we have them:
        // FileAttachment("data/images/fidalgo_2.jpg").href, 
        // etc,
        // etc
        FileAttachment("data/images/fidalgo2.jpeg").href
    ].filter(Boolean);
    buildCarousel(panel.querySelector("#fidalgo-carousel"), photos);

    // Timeline
    panel.querySelector("#fidalgo-timeline")
        .appendChild(createEnhancementTimeline(timeline_data, "Fidalgo Bay"));
        
    // Population plot
    panel.querySelector("#fidalgo-population-plot")
        .appendChild(createFidalgoBayPopulationPlot(fidalgo_pop_est)); // (defined below)

    // Shell height histogram
    // Not yet 100% sure what this will look like, but this is one idea
    // const fidalgoSizeData = fidalgo_heights; // Data will go in here when we have it!! 
    // example for above: 
    // [ann_densities.filter(d => d.location === "Fidalgo Bay" && d.shell_height_mm)]
    panel.querySelector("#fidalgo-size-plot")
        .appendChild(createShellHeightHistogram(fidalgo_heights));

    return panel;
} // END BUILD FIDALGO BAY PANEL

// --- Fidlago Bay Population line chart ---
function createFidalgoBayPopulationPlot(data) {
    if (data.length === 0) {
        return null; 
    }

    return Plot.plot({
        height: 350,
        marginLeft: 60,
        marginRight: 30,
        marginTop: 15,
        marginBottom: 30,
        insetBottom: 20,
        insetTop: 10, 
        x: {
            label: null,
            tickFormat: "d",
            tickSpacing: 60,
            padding: 0.1
        },
        y: {
            label: "Estimated Population",
            grid: true,
            padding: 0.2,
            tickFormat: d => {    // "5.5M" instead of "5,500,000-"
                if (d >= 1_000_000) return (d / 1_000_000).toFixed(1) + "M";
                if (d >= 1_000)     return (d / 1_000).toFixed(0) + "K";
                return d;
            }
        },
        marks: [
            // Soft filled area under the line
            Plot.areaY(data, {
                x: "year",
                y: "population_estimate",
                fill: "#045B4C",
                fillOpacity: 0.08
            }),
            Plot.line(data, {
                x: "year",
                y: "population_estimate",
                stroke: "#045B4C",
                strokeWidth: 2.5
            }),
            Plot.dot(data, {
                x: "year",
                y: "population_estimate",
                fill: "#045B4C",
                stroke: "white",
                strokeWidth: 2,
                r: 4
            }),
            Plot.tip(data, Plot.pointer({
                x: "year",
                y: "population_estimate",
                title: d => `${d.year}: ${d.population_estimate.toLocaleString()}`
            }))
        ],
        style: { fontFamily: "inherit", fontSize: "14px" }
    });
} // END Fidlago Bay pop line plot

// ===================================================
// ===================================================
//
// SITE PANEL: DYES INLET GROUP (Silverdale, Chico Bay, Oyster Bay)
//
// These panels can cross-reference each other and share
// a combined view. Each has its own builder function,
// but they all call the same shared Dyes Inlet plot
// that shows all three sites together. (MAY CHANGE LATER)
//
// ===================================================
// ===================================================

// Add that code in here

// ===================================================
// ===================================================
// FILTER PANEL
// Select visible map layers
// Filter by restoration action
// Drop down menu to jump to sites with written stories
// ===================================================
// ===================================================
function createFilterPanel(enhancementLayer, recruitmentLayer, map, enhData) {
    // Track currently open tooltip 
    // so we can close it before opening a new one
    let currentOpenMarker = null;

    // Create div to hold all this stuff
    const panel = document.createElement("div");

    // Write all static HTML for filter panel
    panel.innerHTML = `
        <div style="padding: 0;">

            <!-- Navigation instructions box -->
            <div style="
                background: linear-gradient(135deg, #f0f7f6 0%, #e8f4f2 100%);
                padding: 16px; border-radius: 6px; border-left: 4px solid #045B4C; margin-bottom: 24px;">
                <div style="font-size: 12px; font-weight: 600; color: #045B4C; margin-bottom: 10px;
                    text-transform: uppercase; letter-spacing: 0.5px;">Navigate the Map</div>
                <div style="font-size: 13px; color: #555; line-height: 1.7;">
                    <p style="margin: 0 0 10px 0;">
                        <strong style="color: #045B4C;">Pan and Zoom:</strong> Click and drag to explore, scroll to zoom
                    </p>
                    <p style="margin: 0;">
                        <strong style="color: #045B4C;">Quick Jump:</strong> Use the dropdown to jump to a story site
                    </p>
                </div>
            </div>

            <!-- Story Site Dropdown (static HTML here, dynamic content added below) -->
            <div style="margin-bottom: 24px;">
                <label style="display: block; font-size: 13px; font-weight: 600; color: #045B4C;
                    margin-bottom: 8px; text-transform: uppercase; letter-spacing: 0.5px;">Read a Story</label>
                <!-- Empty selector, options are added by the JavaScript below -->
                <select id="site-selector" style="
                    width: 100%; padding: 10px 12px; border: 2px solid #e0e0e0; border-radius: 6px;
                    font-size: 14px; background: white; cursor: pointer;
                    transition: all 0.2s ease; color: #333;">
                    <option value="">Select a site...</option>
                </select>
                <div style="font-size: 11px; color: #666; margin-top: 6px; font-style: italic;">
                    Zoom to a site and view its story</div>
            </div>

            <!-- Decorative horizontal divider line -->
            <div style="height: 1px; background: linear-gradient(to right, transparent, #ddd, transparent); margin: 24px 0;"></div>

            <!-- "Customize Your View" instructions box -->
            <div style="
                background: linear-gradient(135deg, #f0f7f6 0%, #e8f4f2 100%);
                padding: 16px; border-radius: 6px; border-left: 4px solid #045B4C; margin-bottom: 24px;
            ">
                <div style="font-size: 12px; font-weight: 600; color: #045B4C; margin-bottom: 10px;
                    text-transform: uppercase; letter-spacing: 0.5px;">Customize Your View</div>
                <div style="font-size: 13px; color: #555; line-height: 1.7;">
                    <p style="margin: 0;">Use the controls below to filter the map</p>
                </div>
            </div>

            <!-- Map Layers: two checkboxes to show/hide data types -->
            <div style="margin-bottom: 20px;">
                <label style="display: block; font-size: 13px; font-weight: 600; color: #045B4C;
                    margin-bottom: 12px; text-transform: uppercase; letter-spacing: 0.5px;">Map Layers</label>
                
                <!-- Enhancement sites checkbox row.
                The outer <label> makes the entire row clickable, not just the checkbox itself. -->
                <label class="filter-checkbox-label" style="display: flex; align-items: center;
                    cursor: pointer; padding: 8px 10px; border-radius: 6px;
                    transition: background 0.2s ease; margin-bottom: 6px; background: #f8f9fa;">
                    <!-- "checked" with no value means it starts ticked by default -->
                    <input type="checkbox" id="enhancement-toggle" checked
                        style="margin-right: 10px; cursor: pointer; width: 16px; height: 16px; accent-color: #045B4C;">
                    <span style="display: flex; align-items: center; gap: 8px; flex: 1;">
                        <!-- Small blue circle that visually matches the enhancement marker on the map -->
                        <div style="background-color: #4e79a7; width: 14px; height: 14px; border-radius: 50%;
                            border: 2px solid white; box-shadow: 0 2px 4px rgba(0,0,0,0.2); flex-shrink: 0;"></div>
                        <span style="font-size: 13px; color: #333; font-weight: 500;">Restoration Enhancements</span>
                    </span>
                </label>

                <!-- Recruitment sites checkbox row -->
                <label class="filter-checkbox-label" style="display: flex; align-items: center;
                    cursor: pointer; padding: 8px 10px; border-radius: 6px;
                    transition: background 0.2s ease; margin-bottom: 6px; background: #f8f9fa;">
                    <input type="checkbox" id="recruitment-toggle" checked
                        style="margin-right: 10px; cursor: pointer; width: 16px; height: 16px; accent-color: #045B4C;">
                    <span style="display: flex; align-items: center; gap: 8px; flex: 1;">
                        <!-- CSS triangle that visually matches the recruitment marker on the map -->
                        <div style="width: 0; height: 0; border-left: 7px solid transparent;
                            border-right: 7px solid transparent; border-bottom: 12px solid #e15759;
                            margin-left: 3px; flex-shrink: 0;"></div>
                        <span style="font-size: 13px; color: #333; font-weight: 500;">Recruitment Monitoring</span>
                    </span>
                </label>

                <div style="font-size: 11px; color: #666; margin-top: 10px; padding-left: 4px; font-style: italic;">
                    Show or hide data types</div>
            </div>

            <!-- Decorative horizontal divider line -->
            <div style="height: 1px; background: linear-gradient(to right, transparent, #ddd, transparent); margin: 24px 0;"></div>

            <!-- Enhancement Type filter: oblong toggle buttons -->
            <div style="margin-bottom: 20px;">
                <label style="display: block; font-size: 13px; font-weight: 600; color: #045B4C;
                    margin-bottom: 8px; text-transform: uppercase; letter-spacing: 0.5px;">
                    Filter by Enhancement Type</label>
                <div style="display: flex; flex-wrap: wrap; gap: 8px; margin-bottom: 8px;">
                    <!-- Each button has a "data-type" attribute -->
                    <button class="type-toggle-btn" data-type="bulk shell" style="
                        padding: 8px 16px; border: 2px solid #045B4C; border-radius: 20px;
                        background: #045B4C; color: white; font-size: 13px; font-weight: 500;
                        cursor: pointer; transition: all 0.2s ease; white-space: nowrap;">Bulk Shell</button>
                    <button class="type-toggle-btn" data-type="seeded cultch" style="
                        padding: 8px 16px; border: 2px solid #045B4C; border-radius: 20px;
                        background: #045B4C; color: white; font-size: 13px; font-weight: 500;
                        cursor: pointer; transition: all 0.2s ease; white-space: nowrap;">Seeded Cultch</button>
                    <button class="type-toggle-btn" data-type="singles" style="
                        padding: 8px 16px; border: 2px solid #045B4C; border-radius: 20px;
                        background: #045B4C; color: white; font-size: 13px; font-weight: 500;
                        cursor: pointer; transition: all 0.2s ease; white-space: nowrap;">Singles</button>
                </div>
                <div style="font-size: 11px; color: #666; margin-top: 6px; font-style: italic;">
                    Select which enhancement methods are displayed</div>
            </div>
        </div>
    `; // END HTML for filter panel

    // Add options to the site selector dropdown dynamically 
    // (so as we add sites, they will add here too!)
    // Find the select element from memory
    const siteSelector = panel.querySelector('#site-selector');

    // Build the list of sites to show in the dropdown
    // Only include sites tha thave valid coordinates and are in story_sites
    const uniqueSites = [...new Set( // Wrapping in Set will remove duplicates, [... ] spreads it to an array
        enhData
            .filter(site =>
                // Keep only rows where ALL of these are trure
                site.latitude && site.longitude &&   // latitude and longitude exist
                site.latitude !== 'NA' && site.longitude !== 'NA' &&   // and aren't the string "NA"
                !isNaN(parseFloat(site.latitude)) && !isNaN(parseFloat(site.longitude)) &&   // and are actual numbers
                story_sites.has(site.site_name)   // and the site has a story panel
            )
            .map(site => site.site_name) // Only keep the site name

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
        const selectedSite = e.target.value;  // the value of the chosen option

        // Only proceed if something was selected AND that site has a marker on the map
        // window.markersBySite is the global object storing all markers by site name
        if (selectedSite && window.markersBySite[selectedSite]) {
            const marker = window.markersBySite[selectedSite];
            const latLng = marker.getLatLng();  // get the marker's coords

            // If a tooltip is already open, close it before opening a new one!!!
            if (currentOpenMarker) currentOpenMarker.closeTooltip();

            // Recenter the map on this site. animate:true makes it look nice!
            map.setView(latLng, 12, { animate: true, duration: 0.5 });

            // Wait 600ms for the zoom animation to finish, then open the tooltip
            // Otherwise things were getting wonky
            setTimeout(() => {
                marker.openTooltip();
                currentOpenMarker = marker;  // remember this as the now-open marker
            }, 600);
        }
    });

    // When the user zooms out past zoom level 11,
    // reset the dropdown back to the placeholder "Select a site..." option
    // Keeps the dropdown in sync with what the map is showing!
    map.on('zoomend', () => {
        if (map.getZoom() < 11) siteSelector.value = '';
    });

    // -----------------------------------------------
    // Wire up the layer toggle checkboxes
    // -----------------------------------------------

    // Find the enhancement checkbox by its ID
    const enhToggle = panel.querySelector('#enhancement-toggle');

    // "change" fires when the checkbox is ticked or unticked
    // e.target.checked is true if the box is now ticked, false if unticked
    // This is a shorthand for an if/else:
    //   if checked: add the layer to the map
    //   if unchecked: remove the layer from the map
    enhToggle.addEventListener('change', (e) => {
        e.target.checked ? enhancementLayer.addTo(map) : enhancementLayer.remove();
    });

    // Do the same but for the recruitment layer
    const recToggle = panel.querySelector('#recruitment-toggle');
    recToggle.addEventListener('change', (e) => {
        e.target.checked ? recruitmentLayer.addTo(map) : recruitmentLayer.remove();
    });

    // -----------------------------------------------
    // Hover effects for the checkbox label rows
    // -----------------------------------------------

    // Find all elements with class "filter-checkbox-label" (both checkbox rows)
    const labels = panel.querySelectorAll('.filter-checkbox-label');

    // For each label, change its background color on mouse enter/leave
    labels.forEach(label => {
        label.addEventListener('mouseenter', () => label.style.background = '#e8f4f2');
        label.addEventListener('mouseleave', () => label.style.background = '#f8f9fa');
    });

    // -----------------------------------------------
    // Enhancement type toggle buttons
    // -----------------------------------------------

    // Start with all 3 enhancement buttons as active
    const activeTypes = new Set(['bulk shell', 'seeded cultch', 'singles']);

    // Take the enhancement_actions column from the CSV and split into an array of strings
    // eg. "bulk shell, seeded cultch" to ["bulk shell", "seeded cultch"]
    // .map(t => t.length >0) removes whitespace
    // .filter(t => t.length > 0) removes any empty strings
    function normalizeType(typeString) {
        if (!typeString) return [];  // if the value is empty, return empty array
        return typeString.split(',').map(t => t.trim().toLowerCase()).filter(t => t.length > 0);
    }

    // Loop through all enhancement sites and show/hide markers
    // based on if it is selected or not
    function filterEnhancementMarkers() {
        enhData.forEach(site => {
            const marker = window.markersBySite[site.site_name];
            if (marker) {
                // Get this sites enhancement types
                const siteTypes = normalizeType(site.enhancement_actions);

                // .some() returns true if at least one item in an array passes test
                const shouldShow = siteTypes.some(type => activeTypes.has(type));

                if (shouldShow) {
                    // hasLayer() checks if the marker is already on the layer —
                    // we only add it if it's not already there, to avoid duplicates
                    if (!enhancementLayer.hasLayer(marker)) enhancementLayer.addLayer(marker);
                } else {
                    if (enhancementLayer.hasLayer(marker)) enhancementLayer.removeLayer(marker);
                }
            }
        });
    }

    // Find all three toggle buttons
    const typeToggleBtns = panel.querySelectorAll('.type-toggle-btn');

    typeToggleBtns.forEach(btn => {
        
        // When a button is clicked toggle it in and out of the activeTypes
        btn.addEventListener('click', () => {
            const type = btn.getAttribute('data-type');

            if (activeTypes.has(type)) {
                // Type was active: deactivate it
                activeTypes.delete(type);
                // Style button as "off": white background, green text
                btn.style.background = 'white';
                btn.style.color = '#045B4C';
            } else {
                // Type was inactive: activate it
                activeTypes.add(type);
                // Style button as "on": green background, white text
                btn.style.background = '#045B4C';
                btn.style.color = 'white';
            }

            // Re-run the marker filter with the updated activeTypes set
            filterEnhancementMarkers();
        });

        // Hover effect: slightly different shade depending on the active state
        btn.addEventListener('mouseenter', () => {
        if (!activeTypes.has(btn.getAttribute('data-type'))) {
            // Inactive button hover: light green tint
            btn.style.background = '#e8f4f2';
            btn.style.color = '#045B4C';
        } else {
            // Active button hover: slightly darker green
            btn.style.background = '#034a3e';
        }
        });

        // When mouse leaves, restore the correct active/inactive style
        btn.addEventListener('mouseleave', () => {
            if (!activeTypes.has(btn.getAttribute('data-type'))) {
                btn.style.background = 'white';
                btn.style.color = '#045B4C';
            } else {
                btn.style.background = '#045B4C';
                btn.style.color = 'white';
            }
        });
    });

    // -----------------------------------------------
    // Dropdown focus/blur styling
    // Adds a green border glow when the dropdown is clicked on,
    // restores the default border when click leaves
    // -----------------------------------------------
    siteSelector.addEventListener('focus', () => {
        siteSelector.style.borderColor = '#045B4C';
        siteSelector.style.boxShadow = '0 0 0 3px rgba(4, 91, 76, 0.1)';
    });
    siteSelector.addEventListener('blur', () => {
        siteSelector.style.borderColor = '#e0e0e0';
        siteSelector.style.boxShadow = 'none';
    });

    // Return the fully built panel element
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
//  - densityData: The population assessments CSV with density .... MAY CHANGE THIS
//  - {width}: the current container width which dynamically comes from resize()
// ===================================================
// ===================================================
function oysterMap(enhData, recruitData, densityData, {width} = {}) {
    
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
    Object.assign(mainContainer.style, {
        width: `${width}px`,
        height: "90vh", // 90% of the browser window for height
        minHeight: "600px" // never shrink below 600px even on small screens
    });

    // The div for the Leaflet map
    // Starts at full width but shrinks to 40% when a story panel opens
    const mapContainer = document.createElement("div");
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
    const recruitmentLayer = L.layerGroup().addTo(map);
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

        // Shrink the map to 40% width
        mapContainer.style.width = "30%";
        mapContainer.style.flexShrink = "0";   // don't let flex squish it any further

        // Show the detail panel as a flex column
        detailContainer.style.display = "flex";

        // Fade the panel in
        // 10ms delay makes sure display:flex is initiated before we try and animate
        setTimeout(() => detailContainer.style.opacity = "1", 10);

        // Tell leaflet the map container changed size, then zoom to the site
        setTimeout(() => {
            map.invalidateSize();  // recalc map dimensions after resize
            map.setView(
                [site.latitude, site.longitude + 0.02],  // Recenter the map here
                13,  // At this zoom level
                { animate: false }  // Jump instantly without an animation
            );
        }, 50);

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
    // ADD RECRUITMENT MARKERS
    // Loop through every row in recruitData and place a
    // red triangle marker for each valid site!
    // ===================================================
    recruitData.forEach(site => {
        // Skip this row if coordinates are missing or invalid
        if(!site.latitude || !site.longitude ||
            site.latitude === 'NA' || site.longitude === 'NA' ||
            isNaN(parseFloat(site.latitude)) || isNaN(parseFloat(site.longitude))) return;
        
        // Create markers, bind tooltip, and add to recruitment layer
        const marker = L.marker(
            [parseFloat(site.latitude), parseFloat(site.longitude)],
            { icon: recruitmentIcon }  // red triange defined at the top of the code
        )
        .bindTooltip(`
            <strong>${site.standard_station}</strong><br>  
            Type: Recruitment Monitoring<br>
            Years: years here
        `, { direction: 'top', permanent: false })   // WE WILL CHANGE THIS ABOVE LATER
        .addTo(recruitmentLayer);

        // Store the marker 
        // RIGHT NOW NOTHING IS USING THIS
        // CAN DELETE LATER IF WE DO NOT RIG UP FILTERS FOR RECRUITMENT BY SITE NAME
        window.markersBySite[site.standard_station] = marker;
    });


    // ===================================================
    // ADD ENHANCEMENT MARKERS
    // Same loop structure as recruitment markers above, but with
    // two key differences:
    //   1. Story sites get the star icon, others get the plain circle
    //   2. Story sites get a click handler that opens the detail panel!!
    // ===================================================
    enhData.forEach(site => {
        // Skip this row if coordinates are missing or invalid
        if(!site.latitude || !site.longitude ||
            site.latitude === 'NA' || site.longitude === 'NA' ||
            isNaN(parseFloat(site.latitude)) || isNaN(parseFloat(site.longitude))) return;

        // story_sites is the Set defined at the top of the file
        // .has() checks if site_name is in that Set
        const isStorySite = story_sites.has(site.site_name);

        // Pick the star icon for story sites, plan circle for others
        // This is called a ternary: condition ? value_if_true : value_if_false
        const icon = isStorySite ? enhancementStoryIcon : enhancementIcon;

        // Build photo HTML for the tooltip if this site has a photo
        // tooltipPhotos is defined at the top
        // If no photo exists, it renders as nothing
        const photoUrl = tooltipPhotos[site.site_name];
        const photoHTML = photoUrl ? `
            <img src="${photoUrl}" style="
            width: 100%; height: 120px; object-fit: cover;
            border-radius: 4px; border: 2px solid #ddd;
            margin-top: 8px; margin-bottom: 8px;">
        ` : "";

        // Story sites get a green "click to explore" banner at the bottom of tooltip
        const clickHint = isStorySite ? `
            <div style="
                margin-top: 8px; padding: 6px 8px;
                background: #f0f7f6; border-radius: 4px;
                font-size: 11px; color: #045B4C; font-weight: 600;
                text-align: center;
            ">▶ Click to explore this site</div>
        ` : "";

        // Create the marker with the right icon
        // By using an arrow function to build the tooltip, we allow
        // Leaflet to build it only when the tooltip is about to open
        // and not at the loading when the marker is created
        const marker = L.marker(
            [site.latitude, site.longitude],
            { icon: icon }
        )
        .bindTooltip(() => `
            <div style="min-width: 200px; padding: 12px;">
                <div style="font-size: 16px; font-weight: bold; text-align: center; margin-bottom: 4px;">
                ${site.site_name}
                </div>
                ${photoHTML}
                <div style="font-size: 12px; margin-top: 4px;">
                    Type: ${site.enhancement_actions}<br>
                    Years: ${site.enhancement_years}
                    </div>
                ${clickHint}
            </div>
        `, {
            direction: 'top',
            permanent: false,
            className: 'custom-tooltip'   // picks up the custom CSS in the <style> block
        })
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
    // LEGEND
    // L.control() creates a Leaflet control
    // onAdd() is called by Leaflet when it's ready to place
    // the control; it must return a DOM element
    // ===================================================
    const legend = L.control({ position: 'topright' });  // Put it in the top right corner

    legend.onAdd = function() {
        // L.DomUtil.create() is Leaflet's helper for creating DOM elements
        // First arg is tag name, second is CSS class
        const div = L.DomUtil.create('div', 'map-legend');

        div.innerHTML = `
            <div style="
                background: white; padding: 12px; border-radius: 8px;
                box-shadow: 0 2px 8px rgba(0,0,0,0.15); font-size: 13px;">

                <!-- No story site row: plain blue circle -->
                <div style="display: flex; align-items: center; margin: 5px 0;">
                    <div style="
                        background-color: #4e79a7; width: 14px; height: 14px; border-radius: 50%;
                        border: 2px solid white; margin-right: 8px; flex-shrink: 0;"></div>
                    Enhancement
                </div>

                <!-- Recruitment row: CSS triangle matching the recruitment marker icon -->
                <div style="display: flex; align-items: center; margin: 5px 0;">
                    <div style="
                        width: 0; height: 0;
                        border-left: 7px solid transparent; border-right: 7px solid transparent;
                        border-bottom: 12px solid #e15759;
                        margin-right: 8px; margin-left: 3px; flex-shrink: 0;"></div>
                    Recruitment Monitoring
                </div>
            </div>
        `;

        // return the element so leaflet can place it
        return div;
    };

    legend.addTo(map);

    // Add scale bar
    L.control.scale({ imperial: true, metric: true }).addTo(map);

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

    // Return the whole assembled container div
    return mainContainer;
} // END MAIN MAP FUNCTION

// // ===================================================
// // INSTANTIATE MAP
// // (programming term = create a real "instance" of a template
// // if all the above code is a template for how to make it,
// // here we say ok, actually make that now)
// // ===================================================
// const mapInstance = resize((width) => {
//   const container = oysterMap(enh_sites_metadata, recruit_sites, ann_densities, { width });
//   window.currentMapInstance = container;

//   setTimeout(() => {
//     // Leaflet to recalculate — don't rebuild anything
//     if (window.currentMapInstance) {
//         window.currentMapInstance.style.width = `${width}px`;
//         window.currentMapInstance._map.invalidateSize();
//         return window.currentMapInstance;
//     }

//     const filterContainer = document.querySelector('#filter-container');
//     if (filterContainer && container._enhancementLayer) {
//       filterContainer.innerHTML = '';
//       filterContainer.appendChild(
//         createFilterPanel(
//           container._enhancementLayer,
//           container._recruitmentLayer,
//           container._map,
//           enh_sites_metadata
//         )
//       );
//     }
//   }, 100);

//   return container;
// });

// ===================================================
// INSTANTIATE MAP
// Build once, place in a persistent div, use
// ResizeObserver to keep width in sync without
// ever rebuilding the map or touching its DOM node.
// ===================================================

// Wait for the placeholder card to exist in the DOM
setTimeout(() => {
    const placeholder = document.querySelector('#map-card-placeholder');
    if (!placeholder) return;

    // Build the map once at the placeholder's actual current width
    const initialWidth = placeholder.offsetWidth || 800;
    const container = oysterMap(
        enh_sites_metadata,
        recruit_sites,
        ann_densities,
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
                    enh_sites_metadata
                )
            );
        }
    }, 100);

    // Watch the placeholder for size changes using ResizeObserver.
    // This fires when the card changes width — e.g. on window resize.
    // We just update the container width and tell Leaflet to redraw.
    // Nothing is rebuilt, no state is lost.
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
<!-- STYLES -->
<!-- =================================================== -->
<style>
  .leaflet-container { font-family: inherit; }

  .leaflet-control-attribution {
    background-color: rgba(255,255,255,0.7);
    font-size: 10px;
    opacity: 0.6;
    padding: 2px 5px;
  }
  .leaflet-control-attribution:hover { opacity: 1; }

  /* -----------------------------------------------
     CAROUSEL
  ----------------------------------------------- */
  .carousel {
    position: relative;
    width: 92%;
    margin: 0 auto 32px auto;  /* centered with breathing room each side */
    background: transparent;
    border-radius: 12px;
    overflow: hidden;
    box-shadow: 0 4px 20px rgba(0,0,0,0.15);
}
.carousel-images {
    position: relative;
    width: 100%;
    padding-bottom: 45%;
}
.carousel-image {
    position: absolute;
    top: 0; left: 0;
    width: 100%; height: 100%;
    object-fit: cover;   /* contain or cover? not sure which i like better yet! */
    opacity: 0;
    transition: opacity 0.3s ease;
    pointer-events: none;
    background: transparent;
    border-radius: 12px;
}
.carousel-image.active { opacity: 1; pointer-events: auto; }
.carousel-btn {
    position: absolute;
    top: 50%;
    transform: translateY(-50%);
    background: rgba(0,0,0,0.35);  /* dark semi-transparent */
    color: white;
    border: none;
    font-size: 28px;
    width: 36px;
    height: 36px;
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    z-index: 10;
    border-radius: 50%;
    transition: background 0.2s ease;
}
.carousel-btn:hover { background: rgba(0,0,0,0.6); }
.carousel-btn.prev { left: 12px; }
.carousel-btn.next { right: 12px; }
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
    width: 8px; height: 8px;
    border-radius: 50%;
    background: rgba(255,255,255,0.5);
    cursor: pointer;
    transition: background 0.2s ease;
}
.carousel-dot.active { background: rgba(255,255,255,1); }
.carousel-dot:hover  { background: rgba(255,255,255,0.8); }

  /* -----------------------------------------------
     TOOLTIP
  ----------------------------------------------- */
  .custom-tooltip { padding: 0 !important; box-shadow: 0 2px 8px rgba(0,0,0,0.15); }
  .custom-tooltip .leaflet-tooltip-content { padding: 0 !important; margin: 0; }
  .custom-tooltip img { display: block; background: #f0f0f0; }

  /* -----------------------------------------------
   STORY SITE MARKER — single pulse on load
   Plays once, then stops. The ring expands and
   fades out a single time after a short delay.
    ----------------------------------------------- */
    @keyframes single-pulse {
        0%   { transform: scale(0.8); opacity: 0.8; }
        70%  { transform: scale(2.2); opacity: 0; }
        100% { transform: scale(2.2); opacity: 0; }
    }

    .story-pulse-ring {
        position: absolute;
        top: 0; left: 0;
        width: 18px;
        height: 18px;
        border-radius: 50%;
        border: 4px solid #045B4C;
        box-sizing: border-box;
        animation: single-pulse 2s ease-out 1 forwards;
    }
</style>


<!-- Display everything in cards on the page -->
<!-- Map card div lives here permanently, outside Observable's control to fix wonkyness with resizing -->
<div id="persistent-map-card" style="grid-column: span 3;"></div>

<div class="grid grid-cols-4">
  <div class="card">
    ${(function() {
      const div = document.createElement('div');
      div.id = 'filter-container';
      return div;
    })()}
  </div>
  <div class="card grid-colspan-3" id="map-card-placeholder"></div>
</div>