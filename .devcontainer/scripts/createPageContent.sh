#!/bin/bash

CURRENT_YEAR=$(date +'%Y')
SUB_DIRS='DISC DISC KAKA KMTP MTSR RIMK TEMO TOKR WHOH'
SUB_DIRS_L2=("DISC.01" "DISC.02" "KAKA.01" "KMTP.01" "MTSR.01" "RIMK.01" "TEMO.02" "TOKR.01" "WHOH.02")
SUB_DIR_NAMES=("Ruapehu North" "Ngauruhoe" "Tongariro" "Ruapehu & Ngauruhoe" "Ruapehu South" "Raoul Island" "Taranaki" "Tongariro Te Maari Crater" "Whakatane")
HTTP_DATA_URL="https://data.geonet.org.nz"

TOP_CONTENT='
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>GeoNet Camera Demo</title>
    <style>
      *{
        box-sizing: border-box;
        -webkit-box-sizing: border-box;
        -moz-box-sizing: border-box;
      }
      body{
        font-family: Helvetica;
        -webkit-font-smoothing: antialiased;
        background: #2b2b2b;
      }
      h1{
        text-align: center;
        text-transform: uppercase;
        letter-spacing: 1px;
        color: white;
        padding: 30px 0;
      }

      /* Table Styles */

      .table-wrapper{
        margin: 10px 70px 70px;
        box-shadow: 0px 35px 50px rgba( 0, 0, 0, 0.2 );
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

      .fl-table thead th:nth-child(odd) {
        color: #ffffff;
        background: #151515;
      }

      .fl-table tr:nth-child(even) {
        background: #F8F8F8;
      }

      /* footer */

      .footer {
        position: fixed;
        left: 0;
        bottom: 0;
        width: 100%;
        color: white;
        text-align: center;
      }

      /* Responsive */

      @media (max-width: 767px) {
        .fl-table {
            display: block;
            width: 100%;
        }
        .table-wrapper:before{
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
        .fl-table thead th:last-child{
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

      /* Open Enlarged Image */
      img {
        cursor: pointer;
        width: 900px;
        max-width: 10%;
        aspect-ratio: 1.5/1;
        display: flex;
        justify-content: center;
        align-items: center;
        text-align: center;
        height: 10%;
        color: white;
        border-radius: 10px;
        transition: all 0.3s ease;

        &:hover {
          transform: scale(1.05);
        }

        &:before {
          border-radius: 15px;
          position: relative;
          background: #ccc;
          z-index: 1;
          height: 10%;
          color: black;
          content: attr(alt);
          display: grid;
          place-items: center;
        }
      }

      .load-image {
        display: block;
        background: #ccc;
        height: 100%;
        width: 100%;
        border-radius: 15px;
        display: grid;
        align-items: center;
        text-align: center;
        text-decoration: none;
        color: black;
        opacity: 0.7;
        transition: all 0.3s ease;

        &:hover {
          opacity: 1;
        }
      }

      .overlay {
          display: none;
          position: fixed;
          top: 0; left: 0; right: 0; bottom: 0;
          background-color: rgba(0, 0, 0, 0.7);
      }

      .modal {
          display: none;
          position: fixed;
          top: 50%; left: 50%;
          transform: translate(-50%, -50%);
          background-color: #fff;
          padding: 20px;
          border-radius: 5px;
          box-shadow: 0 0 10px rgba(0, 0, 0, 0.5);
      }

      .modal img {
          max-width: 100%;
          max-height: 90vh;
      }

      .close {
          position: absolute;
          top: 10px; right: 10px;
          cursor: pointer;
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
      <tbody>'

index=0
for SUB_DIR in $SUB_DIRS; do
  SUB_DIR_L2=$(echo "${SUB_DIRS_L2[$index]}/")
	echo "Processing $SUB_DIR/$SUB_DIR_L2"
  FILTER_URL="${HTTP_DATA_URL}/camera/volcano/images/${CURRENT_YEAR}/${SUB_DIR}/${SUB_DIR_L2}"
  SUB_DIR_L3=$(curl -s $FILTER_URL| grep '^<a href' | tail -n 1 | sed -n 's/.*href="\([^/]*\)\/".*/\1/p')
  FILENAME=$(curl -s $FILTER_URL$SUB_DIR_L3/ | grep '^<a href' | tail -n 1 | sed 's/.*href="\([^"]*\)".*/\1/')
  LATEST_IMAGE_URL=$FILTER_URL$SUB_DIR_L3/$FILENAME
  LOCATION=$(echo "${SUB_DIR_NAMES[$index]}")
  DATETIMESTAMP_RAW="$(echo $FILENAME | grep -oP '\d{4}\.\d{3}\.\d{4}')"
  YEAR=$(echo "$DATETIMESTAMP_RAW" | cut -d '.' -f1)
  DOY=$(echo "$DATETIMESTAMP_RAW" | cut -d '.' -f2)
  TIME=$(echo "$DATETIMESTAMP_RAW" | cut -d '.' -f3)
  DATE_MONTH=$(date -d "$YEAR-01-01 +$((10#$DOY-1)) days" +"%d %B")
  DATETIMESTAMP=$(echo "$DATE_MONTH $YEAR, $TIME")
	BODY_CONTENT+="
        <tr>
            <td>$SUB_DIR/$SUB_DIR_L2</td>
            <td>$LOCATION</td>
            <td>$FILENAME</td>
            <td>$DATETIMESTAMP</td>
            <td>
              <a href=\"${LATEST_IMAGE_URL}\" class=\"trigger\">
                <img src=\"${LATEST_IMAGE_URL}\" alt=\"\">
              </a>
            </td>
        </tr>"
  ((index++))
done

CURRENT_DATE=$(date +"%d %B %Y")
CURRENT_TIME=$(date +"%H%M %Z")
TIME_FORMATTED=$(date -d "$CURRENT_TIME" +"%I:%M %p %Z")

BOTTOM_CONTENT="
      </tbody><tbody> </tbody>
    </table>
  </div>
  <div class=\"overlay\"></div>
  <div class=\"modal\">
    <span class=\"close\">&times;</span>
    <img src=\"\" alt=\"\" />
  </div>
  <div class=\"footer\">
    <p>Last update: $CURRENT_DATE, $TIME_FORMATTED</p>
  </div>
  <script>
    document.querySelectorAll(\".trigger\").forEach(trigger => {
      trigger.addEventListener(\"click\", function (event) {
        event.preventDefault();
        const imageURL = this.getAttribute(\"href\");
        const modal = document.querySelector(\".modal\");
        const enlargedImage = modal.querySelector(\"img\");
        enlargedImage.setAttribute(\"src\", imageURL);
        document.querySelector(\".overlay\").style.display = \"block\";
        modal.style.display = \"block\";
      });
    });

    document.querySelector(\".close\").addEventListener(\"click\", () => closeModal());
    document.querySelector(\".overlay\").addEventListener(\"click\", () => closeModal());

    function closeModal() {
      document.querySelector(\".overlay\").style.display = \"none\";
      document.querySelector(\".modal\").style.display = \"none\";
    }
  </script>
</body>
</html>"

echo "$TOP_CONTENT$BODY_CONTENT$BOTTOM_CONTENT" > docs/index.html

echo "Content written to index.html file."
