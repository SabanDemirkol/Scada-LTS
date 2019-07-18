<%--
    Mango - Open Source M2M - http://mango.serotoninsoftware.com
    Copyright (C) 2006-2011 Serotonin Software Technologies Inc.
    @author Matthew Lohbihler
    
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/.
--%>
<%@ include file="/WEB-INF/jsp/include/tech.jsp" %>
<%@page import="com.serotonin.mango.vo.UserComment"%>

<tag:page dwr="DataPointDetailsDwr" js="view" onload="init">
  <script src="resources/libs/amcharts4/core.js"></script>
  <script src="resources/libs/amcharts4/charts.js"></script>
  <script src="resources/libs/amcharts4/themes/animated.js"></script>
  <script src="resources/libs/jquery-ui/jquery-ui.min.js"></script>
  <script type="text/javascript">

    mango.view.initPointDetails();
    var liveChart = true;

    function init() {
      getHistoryTableData();
      <c:if test="${!empty periodType}">
        DataPointDetailsDwr.getDateRangeDefaults(${periodType}, ${periodCount}, function(data) {
          setDateRange(data);
        });
        </c:if>
        <c:if test="${!empty flipbookLimit}">getFlipbookChart();</c:if>
          getStatsChart();

      jQuery("#datPointDetailsPointSelect").chosen({
        allow_single_deselect: true,
        placeholder_text_single: " ",
        search_contains: true,
        width: "400px"
      });

      hideOldUserNotes();
    }

    //
    // History
    //
    function getHistoryTableData() {
      var limit = parseInt($get("historyLimit"));
      if (isNaN(limit))
        alert("<fmt:message key="pointDetails.recordCountError"/>");
      else {
        startImageFader($("historyLimitImg"));
        DataPointDetailsDwr.getHistoryTableData(limit, function (response) {
          var data = response.data.history;
          dwr.util.removeAllRows("historyTableData");
          if (!data || data.length == 0)
            dwr.util.addRows("historyTableData", ["<fmt:message key="common.noData"/>"], [function (data) { return data; }]);
          else {
            dwr.util.addRows("historyTableData", data,
              [
                function (data) { return data.value; },
                function (data) { return data.time; },
                function (data) { return data.annotation; }
              ],
              {
                rowCreator: function (options) {
                  var tr = document.createElement("tr");
                  tr.className = "row" + (options.rowIndex % 2 == 0 ? "" : "Alt");
                  return tr;
                }
              });
          }
          $("historyTableAsof").innerHTML = response.data.asof;
          stopImageFader($("historyLimitImg"));
        });
      }
    }

    //
    // Stats chart
    //
    function getStatsChart() {
      var period = parseInt($get("statsChartDuration"));
      var periodType = parseInt($get("statsChartDurationType"));

      if (isNaN(period))
        alert("<fmt:message key="pointDetails.timePeriodError"/>");
      else {
        startImageFader($("statsChartImg"));
        DataPointDetailsDwr.getStatsChartData(periodType, period, true, function (response) {
          $("statsChartData").innerHTML = response.data.stats;
          $("statsAsof").innerHTML = response.data.asof;
          stopImageFader($("statsChartImg"));
        });
      }
    }

    function togglePanel(img, panelId) {
      if (!img.minimized) {
        img.src = "images/arrow_out.png";
        img.title = "<fmt:message key="common.maximize"/>";
        hide(panelId);
        img.minimized = true;
      }
      else {
        img.src = "images/arrow_in.png";
        img.title = "<fmt:message key="common.minimize"/>";
        show(panelId);
        img.minimized = false;
      }
    }

    // Flipbook
    function getFlipbookChart() {
      var limit = parseInt($get("flipbookLimit"));
      if (isNaN(limit))
        alert("<fmt:message key="pointDetails.imageCountError"/>");
      else {
        startImageFader($("flipbookChartImg"));
        DataPointDetailsDwr.getFlipbookData(limit, function (response) {
          var data = response.data.images;
          var thumbContent = "";
          for (var i = 0; i < data.length; i++)
            thumbContent += '<img src="' + data[i].uri + '?w=40&h=40" onmouseover="swapFlipbookImage(\'' + data[i].uri + '\')"/>';
          $set("flipbookThumbsDiv", thumbContent);
          if (data.length > 0)
            swapFlipbookImage(data[0].uri);

          $("flipbookAsof").innerHTML = response.data.asof;
          stopImageFader($("flipbookChartImg"));
        });
      }
    }

    function swapFlipbookImage(uri) {
      $("flipbookImage").src = uri;
    }

    jQuery(document).ready(function () {
      var pointId = Number(jQuery("#pointid").text());
      initAmChartPoint(pointId);

      jQuery( ".calendar" ).datepicker();
      jQuery( ".radio-button" ).checkboxradio();
      jQuery("#loadingChartContainer").show();
      setTimeout(function () {
        jQuery("#loadingChartContainer").hide();
        initAmChart();
        liveUpdatePoints();
      }, 500);

      jQuery('#radio-btn-1').change(function() {
            if(jQuery("#radio-btn-1").is(':checked')) {
                jQuery("#config-live-chart").toggle();
                jQuery("#config-chart").toggle();
                liveChart = true;
            } 
        });
        jQuery('#radio-btn-2').change(function() {
            if(jQuery("#radio-btn-2").is(':checked')) {
                jQuery("#config-live-chart").toggle();
                jQuery("#config-chart").toggle();
                liveChart = false;
            } 
        });
      jQuery("#chart-show-button").click(function () {
        initAmChartPoint(pointId);
        jQuery("#loadingChartContainer").show();
        setTimeout(function () {
          jQuery("#loadingChartContainer").hide();
          initAmChart();
          if(liveChart){
            liveUpdatePoints();
          }
        }, 500)
      });




      (function ($) {
        loadjscssfile("resources/jQuery/plugins/chosen/chosen.min.css", "css");
        loadjscssfile("resources/jQuery/plugins/chosen/chosen.jquery.min.js", "js");
      })(jQuery);
    });

    function hideOldUserNotes() {
      var userNotes = document.getElementsByClassName("userNote");
      var limit = document.getElementById("notesLimit").value;
      for (let i = 0; i < (userNotes.length); i++) {
        if (i < userNotes.length - limit) {
          userNotes[i].style.display = "none";
        } else {
          userNotes[i].style.display = "block";
        }
      }
    }

    function calculatePeriod() {
      let period
      if (!isNaN($get("chartPeriodValue")) && $get("chartPeriodValue") > 0) {
        period = $get("chartPeriodValue") * 1000 * 60;
      } else {
        period = 1 * 1000 * 60;
      }

      let type = $get("chartPeriodType");

      if (type > 2)
        period *= 60;
      if (type > 3)
        period *= 24;
      if (type == 5)
        period *= 7;
      else if (type == 6)
        period *= 30;
      else if (type == 7)
        period *= 365;

      return period;
    }

    //amChartVariables
    const API_NAME = "/ScadaLTS";
    var chart;
    var interval;
    var pointPastValues = new Map();
    var pointCurrentState = new Map();
    var lastUpdate = new Map();

    am4core.ready();


    /* AMCHART SECTION */
    function initAmChart() {
      am4core.useTheme(am4themes_animated);
      chart = am4core.create("chartdiv", am4charts.XYChart);

      chart.dateFormatter.inputDateFormat = "yyyy-MM-dd-HH-mm-ss";
      var dateAxis = chart.xAxes.push(new am4charts.DateAxis());
      var valueAxis = chart.yAxes.push(new am4charts.ValueAxis());
      dateAxis.renderer.maxGridDistance = 60;

      // Create series
      pointCurrentState.forEach(function (value, key) {
        var series = chart.series.push(new am4charts.StepLineSeries());
        series.dataFields.valueY = value;
        series.dataFields.dateX = "date";
        series.name = value;
        series.tooltipText = value + ": {" + value + "}"
        series.strokeWidth = 2;
        series.minBulletDistance = 15;

        // Make bullets grow on hover
        var bullet = series.bullets.push(new am4charts.CircleBullet());
        bullet.circle.strokeWidth = 2;
        bullet.circle.radius = 4;
        bullet.circle.fill = am4core.color("#fff");

        var bullethover = bullet.states.create("hover");
        bullethover.properties.scale = 1.3;

        // Drop-shaped tooltips
        series.tooltip.background.cornerRadius = 20;
        series.tooltip.background.strokeOpacity = 0;
        series.tooltip.pointerOrientation = "vertical";
        series.tooltip.label.minWidth = 40;
        series.tooltip.label.minHeight = 40;
        series.tooltip.label.textAlign = "middle";
        series.tooltip.label.textValign = "middle";
      })

      // Make a panning cursor
      chart.cursor = new am4charts.XYCursor();
      chart.cursor.behavior = "panXY";
      chart.cursor.xAxis = dateAxis;

      // Create vertical scrollbar and place it before the value axis
      chart.scrollbarY = new am4core.Scrollbar();
      chart.scrollbarY.parent = chart.leftAxesContainer;
      chart.scrollbarY.toBack();

      // Create a horizontal scrollbar with previe and place it underneath the date axis
      chart.scrollbarX = new am4charts.XYChartScrollbar();
      // chart.scrollbarX.series.push(chart.series.get(0));
      chart.scrollbarX.parent = chart.bottomAxesContainer;
      chart.legend = new am4charts.Legend();

      chart.events.on("ready", function () {
        dateAxis.zoom({ start: 1 / 15, end: 1 });
      });

      chart.data = prepareChartData(sortMapKeys(pointPastValues));
    }

    function initAmChartPoint(pointId) {
      clearChart();
      let period = new Date().getTime() - calculatePeriod();
      if(liveChart) {
        getDataPointValuesFromTime(pointId, period);
      } else {
        let startDate = new Date(jQuery("#start-date")[0].value).getTime();
        let endDate = new Date(jQuery("#end-date")[0].value).getTime();
        getDataPointValuesFromTime(pointId, startDate, endDate);
      }
    }

    /**
     * Start live chart update
     *
     * Refresh chart data using REST API. Request for specific dataPoints every refresh rate.
     */
    function liveUpdatePoints() {

      let refreshInterval = Number($get("refreshPeriodValue")) * 1000
      if ($get("refreshPeriodType") == "2") { refreshInterval = refreshInterval * 60; }

      interval = setInterval(function () {
        pointCurrentState.forEach(function (value, key) {
          jQuery.get(API_NAME + "/api/point_value/getValue/id/" + key, function (data, status) {
            if (status == "success") {
              data = JSON.parse(data);
              //Do the same as it was in getDataPointValuesFromTime()
              if (isNaN(data.value)) {
                data.value == "true" ? data.value = 1 : data.value = 0;
              }
              let point = { 'name': data.name, "value": data.value };
              if (lastUpdate.get(data.ts) == undefined) {
                lastUpdate.set(data.ts, [point]);
              } else {
                lastUpdate.get(data.ts).push(point);
              }
            }
          })
        })
        setTimeout(function () {
          chart.addData(prepareChartData(sortMapKeys(lastUpdate)))
          lastUpdate.clear();
        }, 500)

      }, refreshInterval);
    }

    /**
     * Get point values from time
     *
     * Load data from REST API and populate dataPoint variables.
     *
     * @param {number} pointId - DataPoint ID in database
     * @param {number} endTimestamp - Ending timestamp (default: now)
     */
    function getDataPointValuesFromTime(pointId, startTimestamp = new Date().getTime() - (24*60*60*1000), endTimestamp = new Date().getTime()) {
      jQuery.get(API_NAME + "/api/point_value/getValuesFromTimePeriod/" + pointId + "/" + startTimestamp + "/" + endTimestamp, function(data, status) {
        if (status == "success") {
          data = JSON.parse(data)
          if (pointCurrentState.get(pointId) == undefined) {
            pointCurrentState.set(pointId, data.name);
          }
          data.values.forEach(e => {
            //Validate binary values and transform to numeric values
            if (isNaN(e.value)) {
              e.value == "true" ? e.value = 1 : e.value = 0;
            }
            let point = { "name": data.name, "value": e.value };
            // If point value in time do not exist - create new one
            if (pointPastValues.get(e.ts) == undefined) {
              pointPastValues.set(e.ts, [point])
            } else {
              pointPastValues.get(e.ts).push(point)
            }
          })
        } else {
          alert(status)
        }
      })
    }

    // --- UTILS --- //
    function sortMapKeys(map) {
      var sortByKeys = (a, b) => a[0] > b[0] ? 1 : -1
      return new Map([...map].sort(sortByKeys))
    }

    /**
     * Clear chart data before starting another one
     */
    function clearChart() {
      clearInterval(interval);
      pointCurrentState.clear();
      pointPastValues.clear();
      lastUpdate.clear();
    }

    /**
     * Convert from Map structure to amChart data interface
     *
     * @param {Map} map - Values map to be converted. 
     * @return {Array} amChart data structure.
     */
    function prepareChartData(map) {
      let data = []; // [{date:<time>, <datapointName>:<datapointValue>}]
      map.forEach(function (value, key) {
        let jsonString = '{ "date":' + key
        value.forEach(e => {
          if (!isNaN(Number(e.value))) {
            jsonString = jsonString + ', "' + e.name + '":' + e.value
          }
        })
        jsonString = jsonString + '}';
        data.push(JSON.parse(jsonString));
      });
      return data;
    }

  </script>

  <style>
    @import "resources/css/scada_ui.css";
    @import "resources/libs/jquery-ui/jquery-ui.min.css";
    .line-title {
      display: inline;
    }

    .dps-detail {
      display: flex;
      padding: 10px 0px 10px 0px;
      border-bottom: 1px solid #90df9ba9;
    }
    .flex-end {
      justify-content: flex-end;
    }

    .dps-detail .detail-key {
      width: 30%;
    }

    .chart-selects {
      flex-direction: column;
      width: 25vw;
    }

    #pointid {
      display: none;
    }

    #chartdiv {
      min-height: 50vh;
    }

    #loadingChartContainer {
      justify-content: center;
    }

    #historyTableContainer {
      max-height: 45vh;
      overflow: auto;
    }
    #historyTableDOM {
      width: 100%;
    }



    @media (max-width: 1200px) {
      #dpd-details, #dpd-access {
        order: -1;
      }
    }
  </style>

  <div>
    <div class="scada-header flex-row flex-row-wrap flex-align-center">
      <span class="title-standard">${point.name}</span>
      <span id="pointid">${point.id}</span>
      <div id="point-navigation-container" class="flex-align-center">
        <fmt:message key="pointDetails.goto" />:&nbsp;
        <sst:select id="datPointDetailsPointSelect" value="${point.id}"
          onchange="window.location='data_point_details.shtm?dpid='+ this.value;">
          <c:forEach items="${userPoints}" var="point">
            <sst:option value="${point.id}">${point.extendedName}</sst:option>
          </c:forEach>
        </sst:select>

        <c:if test="${!empty prevId}">
          <tag:img png="bullet_go_left" title="pagination.previous"
            onclick="window.location='data_point_details.shtm?dpid=${prevId}'" />
        </c:if>

        <c:if test="${!empty nextId}">
          <tag:img png="bullet_go" title="pagination.next"
            onclick="window.location='data_point_details.shtm?dpid=${nextId}'" />
        </c:if>
      </div>
    </div>
    <div class="flex-row-wrap flex-space-between">
      <div id="dpd-details" class="scada-card-4 flex-column">
          <div id="dpd-point-details" class="scada-card">
              <div class="scada-header flex-row-wrap flex-align-center">
                <h4 class="title-small"><fmt:message key="watchlist.pointDetails"/></h4>
                <span class="flex-spacer"></span>
                <c:if test="${pointEditor}">
                  <a href="data_point_edit.shtm?dpid=${point.id}">
                    <tag:img png="icon_comp_edit" title="pointDetails.editPoint" /></a>
                  <a href="data_source_edit.shtm?dsid=${point.dataSourceId}&pid=${point.id}">
                    <tag:img png="icon_ds_edit" title="pointDetails.editDataSource" /></a>
                </c:if>
              </div>
      
              <div class="dps-detail">
                <div class="detail-key">
                  <fmt:message key="common.xid" />
                </div>
                <div class="detail-value">
                  ${point.xid}
                </div>
              </div>
              <div class="dps-detail">
                <div class="detail-key">
                  <fmt:message key="common.time" />
                </div>
                <div id="pointValueTime" class="detail-value">
                </div>
              </div>
              <div class="dps-detail">
                <div class="detail-key">
                  <fmt:message key="common.value" />
                </div>
                <div id="pointValue" class="detail-value">
                </div>
              </div>
              <div id="pointChangeNode" class="dps-detail">
                <div class="detail-key">
                  <tag:img id="pointChanging" png="icon_edit" title="common.set" />
                  <fmt:message key="common.set" />
                </div>
                <div id="pointChange" class="detail-value">
                </div>
              </div>
              <div id="pointMessages" class="dps-detail-long">
              </div>
      
          </div>
          <div id="dpd-user-notes" class="scada-card">
              <div class="scada-header flex-row-wrap flex-align-center">
                <h4 class="title-small">
                  <fmt:message key="notes.userNotes" />
                </h4>
                <span class="flex-spacer"></span>
                <div>
                  <tag:img png="comment_add" title="notes.addNote"
                    onclick="openCommentDialog(${applicationScope['constants.UserComment.TYPE_POINT']}, ${point.id})" />
                </div>
              </div>
              <div>
                <fmt:message key="pointDetails.show" />
                <input id="notesLimit" type="text" style="text-align:right;" value="5" class="formVeryShort" />
                <fmt:message key="pointDetails.mostRecentRecords" />
                <tag:img png="control_play_blue" onclick="hideOldUserNotes()" />
              </div>
              <div>
                <table id="pointComments${point.id}">
                  <tag:comments comments="${point.comments}" />
                </table>
              </div>
          </div>
      </div>
      <div id="dpd-statistics" class="scada-card-4">
        <div class="scada-header flex-row-wrap flex-align-center">
          <h4 class="title-small">
            <fmt:message key="pointDetails.statistics" />
          </h4>
          <span class="flex-spacer"></span>
          <span id="statsAsof"></span>
          <div>
            <fmt:message key="pointDetails.timePeriod" />:
            <input id="statsChartDuration" style="text-align:right;" type="text" class="formVeryShort"
              value='${empty periodCount ? "1" : periodCount}' />
            <sst:select id="statsChartDurationType" value="${periodType}">
              <tag:timePeriodOptions sst="true" min="true" h="true" d="true" w="true" mon="true" />
            </sst:select>
            <tag:img id="statsChartImg" png="control_play_blue" title="pointDetails.getStatistics"
              onclick="getStatsChart()" />
          </div>
        </div>
        <div id="statsChartData">
        </div>
      </div>
      <div id="dpd-history" class="scada-card-4">
        <div class="scada-header flex-row-wrap flex-align-center">
          <h4 class="title-small">
            <fmt:message key="pointDetails.history" />
          </h4>
          <span class="flex-spacer"></span>
          <span id="historyTableAsof"></span>
          <div>
            <fmt:message key="pointDetails.show" />
            <input id="historyLimit" type="text" style="text-align:right;" value="${historyLimit}"
              class="formVeryShort" />
            <fmt:message key="pointDetails.mostRecentRecords" />
            <tag:img id="historyLimitImg" png="control_play_blue" title="pointDetails.getData"
              onclick="getHistoryTableData()" />
          </div>
        </div>
        <div id="historyTableContainer">
          <table id="historyTableDOM" cellspacing="1">
            <tr class="rowHeader">
              <td>
                <fmt:message key="common.value" />
              </td>
              <td>
                <fmt:message key="common.time" />
              </td>
              <td>
                <fmt:message key="common.annotation" />
              </td>
            </tr>
            <tbody id="historyTableData"></tbody>
          </table>
        </div>

      </div>
      <div id="dpd-access" class="scada-card-4 flex-column">
        <div id="dpd-user-access" class="scada-card">
          <div class="scada-header flex-row-wrap flex-align-center">
            <h4 class="title-small">
              <fmt:message key="pointDetails.userAccess" />
            </h4>
            <span class="flex-spacer"></span>
          </div>
          <div>
            <table width="100%" cellspacing="1">
              <tr class="rowHeader">
                <td width="16"></td>
                <td>
                  <fmt:message key="pointDetails.username" />
                </td>
                <td>
                  <fmt:message key="pointDetails.accessType" />
                </td>
              </tr>
              <c:forEach items="${users}" var="userData" varStatus="status">
                <tr class="row<c:if test=" ${status.index % 2==1}">Alt</c:if>">
                  <c:set var="user" value="${userData.user}" />
                  <td><%@ include file="/WEB-INF/snippet/userIcon.jsp" %></td>
                  <td>${user.username}</td>
                  <td>
                    <c:choose>
                      <c:when
                        test="${userData.accessType == applicationScope['constants.Permissions.DataPointAccessTypes.READ']}">
                        <fmt:message key="common.access.read" />
                      </c:when>
                      <c:when
                        test="${userData.accessType == applicationScope['constants.Permissions.DataPointAccessTypes.SET']}">
                        <fmt:message key="common.access.set" />
                      </c:when>
                      <c:when
                        test="${userData.accessType == applicationScope['constants.Permissions.DataPointAccessTypes.DATA_SOURCE']}">
                        <fmt:message key="common.access.dataSource" />
                      </c:when>
                      <c:when
                        test="${userData.accessType == applicationScope['constants.Permissions.DataPointAccessTypes.ADMIN']}">
                        <fmt:message key="common.access.admin" />
                      </c:when>
                      <c:otherwise>
                        <fmt:message key="common.unknown" /> (${userData.accessType})</c:otherwise>
                    </c:choose>
                  </td>
                </tr>
              </c:forEach>
            </table>
          </div>
        </div>
        <div id="dpd-views" class="scada-card">
          <div class="scada-header flex-row-wrap flex-align-center">
            <h4 class="title-small">
              <fmt:message key="pointDetails.views" />
            </h4>
            <span class="flex-spacer"></span>
          </div>
          <div>
            <table width="100%" cellspacing="1">
              <tr class="rowHeader">
                <td>
                  <fmt:message key="pointDetails.name" />
                </td>
                <td></td>
              </tr>
              <c:forEach items="${views}" var="view" varStatus="status">
                <tr class="row<c:if test=" ${status.index % 2==1}">Alt</c:if>">
                  <td>${view.name}</td>
                  <td align="center"><a href="views.shtm?viewId=${view.id}">
                      <tag:img png="icon_view" title="pointDetails.gotoView" /></a></td>
                </tr>
              </c:forEach>
              <c:if test="${empty views}">
                <tr class="row">
                  <td colspan="2">
                    <fmt:message key="pointDetails.notInView" />
                  </td>
                </tr>
              </c:if>
            </table>

          </div>
        </div>
      </div>
      <div id="dpd-chart" class="scada-card">

        <div class="flex-column">
            <div class="scada-card flex-row flex-end">
                <div id="config-live-chart">
                    <div>
                        <span><fmt:message key="watchlist.chart.liveLast"/></span>
                        <div>
                            <input type="number" id="chartPeriodValue" value="60"/>
                            <select id="chartPeriodType">
                                <tag:timePeriodOptions min="true" h="true" d="true" w="true" mon="true" y="true"/>
                            </select>
                        </div>
                    </div>
                    <div>
                        <span><fmt:message key="watchlist.chart.liveRefresh"/></span>
                        <div>
                            <input type="number" id="refreshPeriodValue" value="10"/>
                            <select id="refreshPeriodType">
                                <tag:timePeriodOptions s="true" min="true"/>
                            </select>
                        </div>
                    </div>
                </div>
                <div id="config-chart" style="display: none;">
                    <div>
                        <span><fmt:message key="watchlist.chart.start"/></span>
                        <div>
                            <input type="text" class="calendar" name="date" id="start-date" autocomplete="off">
                        </div>
                    </div>
                    <div>
                        <span><fmt:message key="watchlist.chart.end"/></span>
                        <div>
                            <input type="text" class="calendar" name="date" id="end-date" autocomplete="off">
                        </div>
                    </div>
                </div>
                <div class="flex-column chart-button-container">
                    <label for="radio-btn-1"><fmt:message key="watchlist.chart.liveChart"/></label>
                    <input type="radio" class="radio-button" name="radio-btn-1" id="radio-btn-1" checked>
                    <label for="radio-btn-2"><fmt:message key="watchlist.chart.valueChart"/></label>
                    <input type="radio" class="radio-button" name="radio-btn-1" id="radio-btn-2">
                    <button id="chart-show-button" class="ui-button ui-widget ui-corner-all"><fmt:message key="watchlist.chart.launch"/></button>
                </div>
            </div>
            <span class="title-standard scada-card-2" id="chart-title">Chart</span>
        </div>
        <div class="flex" style="display:none;" id="loadingChartContainer">
          <img src="images/hourglass.png" class="loader" />
        </div>
        <div id="chartdiv"></div>
        <div>

        </div>
      </div>
      <div id="dpd-events" class="scada-card">
        <div class="scada-header flex-row-wrap flex-align-center">
          <h4 class="title-small">
            <fmt:message key="pointDetails.events" />
          </h4>
          <span class="flex-spacer"></span>
          <div>
            <tag:img png="arrow_in" title="common.maximize" onclick="togglePanel(this, 'eventsTable');" />
            <a href="">
              <tag:img png="control_repeat_blue" title="common.refresh" /></a>
          </div>
        </div>
        <div class="events-table">
          <table id="eventsTable" cellspacing="1" cellpadding="0" width="100%">
            <tr class="rowHeader">
              <td>
                <fmt:message key="pointDetails.id" />
              </td>
              <td>
                <fmt:message key="common.alarmLevel" />
              </td>
              <td>
                <fmt:message key="common.activeTime" />
              </td>
              <td>
                <fmt:message key="pointDetails.message" />
              </td>
              <td>
                <fmt:message key="common.status" />
              </td>
              <td>
                <fmt:message key="events.acknowledged" />
              </td>
            </tr>

            <c:forEach items="${events}" var="event" varStatus="status" end="19">
              <tr class="row<c:if test=" ${status.index % 2==1}">Alt</c:if>">
                <td align="center">${event.id}</td>
                <td align="center">
                  <tag:eventIcon event="${event}" />
                </td>
                <td>${sst:time(event.activeTimestamp)}</td>
                <td>
                  <table cellspacing="0" cellpadding="0" width="100%">
                    <tr>
                      <td><b>
                          <sst:i18n message="${event.message}" /></b></td>
                      <td align="right">
                        <tag:img png="comment_add" title="notes.addNote"
                          onclick="openCommentDialog(${applicationScope['constants.UserComment.TYPE_EVENT']}, ${event.id})" />
                      </td>
                    </tr>
                  </table>
                  <table cellspacing="0" cellpadding="0" id="eventComments${event.id}">
                    <c:forEach items="${event.eventComments}" var="comment">
                      <tr>
                        <td valign="top" width="16">
                          <tag:img png="comment" title="notes.note" />
                        </td>
                        <td valign="top">
                          <span class="copyTitle">
                            ${comment.prettyTime}
                            <fmt:message key="notes.by" />
                            <c:choose>
                              <c:when test="${empty comment.username}">
                                <fmt:message key="common.deleted" />
                              </c:when>
                              <c:otherwise>${comment.username}</c:otherwise>
                            </c:choose>
                          </span><br />
                          ${comment.comment}
                        </td>
                      </tr>
                    </c:forEach>
                  </table>
                </td>
                <td>
                  <c:choose>
                    <c:when test="${event.active}">
                      <fmt:message key="common.active" />
                      <a href="events.shtm">
                        <tag:img png="flag_white" title="common.active" /></a>
                    </c:when>
                    <c:when test="${!event.rtnApplicable}">
                      <fmt:message key="common.nortn" />
                    </c:when>
                    <c:otherwise>
                      ${sst:time(event.rtnTimestamp)} -
                      <sst:i18n message="${event.rtnMessage}" />
                    </c:otherwise>
                  </c:choose>
                </td>
                <td>
                  <c:if test="${event.acknowledged}">
                    ${sst:time(event.acknowledgedTimestamp)}
                    <sst:i18n message="${event.ackMessage}" />
                  </c:if>
                </td>
              </tr>
            </c:forEach>
            <c:if test="${sst:size(events) > 20}">
              <tr class="row">
                <td align="center" colspan="6">
                  <fmt:message key="pointDetails.maxEvents" /> ${sst:size(events)}</td>
              </tr>
            </c:if>
            <c:if test="${empty events}">
              <tr class="row">
                <td colspan="6">
                  <fmt:message key="events.emptyList" />
                </td>
              </tr>
            </c:if>
          </table>

        </div>

      </div>




    </div>


    <c:if test="${!empty periodType}">
      <table style="display: none">
      <tr >
        <td colspan="3">
          <!--  chart with editable properties and annotations -->
          <div class="borderDiv marB">
            <table width="100%">
              <tr>
                <td class="smallTitle"><fmt:message key="pointDetails.chart"/></td>
                <td id="imageChartAsof"></td>
                <td align="right"><tag:dateRange/></td>
                <td><tag:img id="imageChartImg" png="control_play_blue" title="pointDetails.imageChartButton"
                        onclick="getImageChart()"/></td>
              </tr>
              <tr><td colspan="3" id="imageChartDiv"></td></tr>
            </table>
          </div>
        </td>
      </tr>
    </table>
    </c:if>

  </div>

  <%@ include file="/WEB-INF/jsp/include/userComment.jsp" %>
</tag:page>