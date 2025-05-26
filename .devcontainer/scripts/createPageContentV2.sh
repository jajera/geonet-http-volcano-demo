#!/bin/bash

# Configuration
CURRENT_YEAR=$(date +'%Y')
HTTP_DATA_URL="https://data.geonet.org.nz"
CACHE_DIR="/tmp/geonet-cache"
CACHE_EXPIRY=300 # 5 minutes in seconds

# Camera configuration - easier to maintain and update
declare -A CAMERAS=(
    ["DISC/DISC.01"]="Ruapehu North"
    ["DISC/DISC.02"]="Ngauruhoe"
    ["KAKA/KAKA.01"]="Tongariro"
    ["KMTP/KMTP.01"]="Ruapehu & Ngauruhoe"
    ["MTSR/MTSR.01"]="Ruapehu South"
    ["RIMK/RIMK.01"]="Raoul Island"
    ["TEMO/TEMO.02"]="Taranaki"
    ["TKAH/TKAH.01"]="Te Kaha"
    ["TOKR/TOKR.01"]="Tongariro Te Maari Crater"
    ["WHOH/WHOH.02"]="Whakatane"
)

# Create cache directory if it doesn't exist
mkdir -p "$CACHE_DIR"

# Function to fetch and cache data
fetch_and_cache() {
    local url=$1
    local cache_file="$CACHE_DIR/$(echo "$url" | md5sum | cut -d' ' -f1)"
    
    # Check if cache is valid
    if [ -f "$cache_file" ] && [ $(($(date +%s) - $(stat -c %Y "$cache_file"))) -lt $CACHE_EXPIRY ]; then
        cat "$cache_file"
    else
        # Add error handling for curl
        local response=$(curl -s -w "\n%{http_code}" "$url")
        local status_code=$(echo "$response" | tail -n1)
        local content=$(echo "$response" | sed '$d')
        
        if [ "$status_code" = "200" ]; then
            echo "$content" | tee "$cache_file"
        else
            echo "Error: Failed to fetch $url (Status code: $status_code)" >&2
            return 1
        fi
    fi
}

# Function to parse date from filename
parse_date() {
    local filename=$1
    local year=$(echo "$filename" | grep -oP '^\d{4}(?=\.)')
    local doy=$(echo "$filename" | grep -oP '(?<=\.)\d{3}(?=\.)')
    local time=$(echo "$filename" | grep -oP '(?<=\.)\d{4}(?=\.)')
    
    # Convert DOY to date
    local date_month=$(date -d "$year-01-01 +$((10#$doy - 1)) days" +"%d %B" | tr -d '\n')
    
    # Format time as HH:MM
    local formatted_time=$(echo "$time" | sed -E 's/([0-9]{2})([0-9]{2})/\1:\2/')
    
    # Combine date and time with proper formatting, ensure single line
    echo -n "$date_month $year, $formatted_time"
}

# Function to get latest directory
get_latest_directory() {
    local base_url=$1
    local content=$(fetch_and_cache "$base_url")
    if [ $? -eq 0 ]; then
        echo "$content" | grep -oP '(?<=href=")[^/]+(?=/")' | grep -v '^\.\.$' | sort -r | head -n1
    fi
}

# Function to get latest image
get_latest_image() {
    local dir_url=$1
    local content=$(fetch_and_cache "$dir_url")
    if [ $? -eq 0 ]; then
        echo "$content" | grep -oP '(?<=href=")[^"]+\.jpg(?=")' | sort -r | head -n1
    fi
}

# Function to generate HTML content
generate_html() {
    local body_content=""
    local error_count=0
    
    for camera_id in "${!CAMERAS[@]}"; do
        local location="${CAMERAS[$camera_id]}"
        local base_url="${HTTP_DATA_URL}/camera/volcano/images/${CURRENT_YEAR}/${camera_id}/"
        
        echo "Processing camera: $camera_id ($location)" >&2
        
        # Get latest directory
        local latest_dir=$(get_latest_directory "$base_url")
        
        if [ -n "$latest_dir" ]; then
            echo "Found directory: $latest_dir" >&2
            local dir_url="${base_url}${latest_dir}/"
            
            # Get latest image
            local latest_image=$(get_latest_image "$dir_url")
            
            if [ -n "$latest_image" ]; then
                echo "Found image: $latest_image" >&2
                local image_url="${dir_url}${latest_image}"
                local datetime=$(parse_date "$latest_image")
                
                body_content+="<tr><td>${camera_id}/</td><td>${location}</td><td>${latest_image}</td><td>${datetime}</td><td><a href=\"${image_url}\" class=\"trigger\"><img src=\"${image_url}\" alt=\"${location}\" loading=\"lazy\"></a></td></tr>"
            else
                echo "Warning: No images found for $camera_id in directory $latest_dir" >&2
                ((error_count++))
            fi
        else
            echo "Warning: No directories found for $camera_id" >&2
            ((error_count++))
        fi
    done
    
    if [ $error_count -gt 0 ]; then
        echo "Warning: $error_count cameras had issues fetching data" >&2
    fi
    
    echo "$body_content"
}

# Generate the complete HTML
cat >docs/index.html <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>GeoNet Camera Demo</title>
    <style>
        * {
            box-sizing: border-box;
            -webkit-box-sizing: border-box;
            -moz-box-sizing: border-box;
        }
        
        body {
            font-family: Helvetica, Arial, sans-serif;
            -webkit-font-smoothing: antialiased;
            background: #2b2b2b;
            margin: 0;
            padding: 0;
        }
        
        h1 {
            text-align: center;
            text-transform: uppercase;
            letter-spacing: 1px;
            color: white;
            padding: 30px 0;
            margin: 0;
        }
        
        .table-wrapper {
            margin: 10px 70px 70px;
            box-shadow: 0px 35px 50px rgba(0, 0, 0, 0.2);
        }
        
        .fl-table {
            border-radius: 5px;
            font-size: 12px;
            font-weight: normal;
            border: none;
            border-collapse: collapse;
            width: 100%;
            max-width: 100%;
            white-space: nowrap;
            background-color: white;
        }
        
        .fl-table td, .fl-table th {
            text-align: center;
            padding: 8px;
        }
        
        .fl-table td {
            border-right: 1px solid #f8f8f8;
            font-size: 12px;
        }
        
        .fl-table thead th {
            color: #ffffff;
            background: #151515;
        }
        
        .fl-table tr:nth-child(even) {
            background: #F8F8F8;
        }
        
        .footer {
            position: fixed;
            left: 0;
            bottom: 0;
            width: 100%;
            color: white;
            text-align: center;
            background: rgba(0, 0, 0, 0.5);
            padding: 10px 0;
        }
        
        img {
            cursor: pointer;
            width: 900px;
            max-width: 10%;
            aspect-ratio: 1.5/1;
            object-fit: cover;
            border-radius: 10px;
            transition: all 0.3s ease;
        }
        
        img:hover {
            transform: scale(1.05);
        }
        
        .overlay {
            display: none;
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background-color: rgba(0, 0, 0, 0.7);
            z-index: 1000;
        }
        
        .modal {
            display: none;
            position: fixed;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            background-color: #fff;
            padding: 20px;
            border-radius: 5px;
            box-shadow: 0 0 10px rgba(0, 0, 0, 0.5);
            z-index: 1001;
        }
        
        .modal img {
            max-width: 90vw;
            max-height: 90vh;
            width: auto;
            height: auto;
        }
        
        .close {
            position: absolute;
            top: 10px;
            right: 10px;
            cursor: pointer;
            font-size: 24px;
            color: #666;
        }
        
        .close:hover {
            color: #000;
        }
        
        @media (max-width: 767px) {
            .table-wrapper {
                margin: 10px 20px 70px;
            }
            
            .fl-table {
                display: block;
                width: 100%;
            }
            
            .table-wrapper:before {
                content: "Scroll horizontally >";
                display: block;
                text-align: right;
                font-size: 11px;
                color: white;
                padding: 0 0 10px;
            }
            
            .fl-table thead, .fl-table tbody, .fl-table thead th {
                display: block;
            }
            
            .fl-table thead th:last-child {
                border-bottom: none;
            }
            
            .fl-table thead {
                float: left;
            }
            
            .fl-table tbody {
                width: auto;
                position: relative;
                overflow-x: auto;
            }
            
            .fl-table td, .fl-table th {
                padding: 20px .625em .625em .625em;
                height: 60px;
                vertical-align: middle;
                box-sizing: border-box;
                overflow-x: hidden;
                overflow-y: auto;
                width: 120px;
                font-size: 13px;
                text-overflow: ellipsis;
            }
            
            .fl-table thead th {
                text-align: left;
                border-bottom: 1px solid #f7f7f9;
            }
            
            .fl-table tbody tr {
                display: table-cell;
            }
            
            .fl-table tbody tr:nth-child(odd) {
                background: none;
            }
            
            .fl-table tr:nth-child(even) {
                background: transparent;
            }
            
            .fl-table tr td:nth-child(odd) {
                background: #F8F8F8;
                border-right: 1px solid #E6E4E4;
            }
            
            .fl-table tr td:nth-child(even) {
                border-right: 1px solid #E6E4E4;
            }
            
            .fl-table tbody td {
                display: block;
                text-align: center;
            }
        }
    </style>
</head>
<body>
    <h1>GeoNet Camera Demo</h1>
    <div class="table-wrapper">
        <table class="fl-table">
            <thead>
                <tr>
                    <th>Id</th>
                    <th>Location</th>
                    <th>Filename</th>
                    <th>Date Timestamp (UTC)</th>
                    <th>Image</th>
                </tr>
            </thead>
            <tbody>
                $(generate_html)
            </tbody>
        </table>
    </div>
    <div class="overlay"></div>
    <div class="modal">
        <span class="close">&times;</span>
        <img src="" alt="" />
    </div>
    <div class="footer">
        <p>Last update: $(date +"%d %B %Y, %I:%M %p %Z")</p>
    </div>
    <script>
        // Image loading and modal functionality
        document.querySelectorAll(".trigger").forEach(trigger => {
            trigger.addEventListener("click", function(event) {
                event.preventDefault();
                const imageURL = this.getAttribute("href");
                const modal = document.querySelector(".modal");
                const enlargedImage = modal.querySelector("img");
                enlargedImage.setAttribute("src", imageURL);
                document.querySelector(".overlay").style.display = "block";
                modal.style.display = "block";
            });
        });

        // Close modal functionality
        document.querySelector(".close").addEventListener("click", () => closeModal());
        document.querySelector(".overlay").addEventListener("click", () => closeModal());

        function closeModal() {
            document.querySelector(".overlay").style.display = "none";
            document.querySelector(".modal").style.display = "none";
        }

        // Auto-refresh functionality
        setInterval(() => {
            window.location.reload();
        }, 300000); // Refresh every 5 minutes
    </script>
</body>
</html>
EOF

echo "Content written to index.html file."
