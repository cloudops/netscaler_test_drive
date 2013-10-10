<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <meta http-equiv="content-type" content="text/html; charset=utf-8"/>
    <title>Control Panel</title>
    <link rel="stylesheet" type="text/css" href="/static/css/iphone-toggle.css">
    <link rel="stylesheet" type="text/css" href="/static/css/style.css">
    <script src="/static/js/jquery-1.10.2.min.js"></script>
    <script type="text/javascript" src="/static/js/json2.js"></script>
    <script type="text/javascript" src="http://www.google.com/jsapi"></script>
    <script type="text/javascript">
      google.load('visualization', '1', {packages: ['annotatedtimeline']});
    </script>
    <script type="text/javascript">
      var countdown;
      function drawVisualizations() {
        $(".refresh-in").html(59);
        clearInterval(countdown);
        countdown = setInterval(function(){
          sec=parseInt($(".refresh-in").html()); 
          if (sec != 0) {
            $(".refresh-in").html(sec-1);
          }
        },1000);

        var cpu_qa = {  
          "namespace": "AWS/EC2",       // CloudWatch namespace (string)
          "metric": "CPUUtilization",   // CloudWatch metric (string)
          "unit": "Percent",            // CloudWatch unit (string)
          "statistics": ["Average"],      // CloudWatch statistics (list of strings)
          "period": 600,                // CloudWatch period (int)
          "cloudwatch_queries":         // (list of dictionaries)
          [   
            {
              "prefix": "CPU ",   // label prefix for associated data sets (string)
              "dimensions": { "InstanceId": "i-f361b7c4"}, // CloudWatch dimensions (dictionary)
              "region": "us-west-2"
            }
          ]
        };

        var mem_qa = {  
          "namespace": "System/Linux",       // CloudWatch namespace (string)
          "metric": "MemoryUtilization",   // CloudWatch metric (string)
          "unit": "Percent",            // CloudWatch unit (string)
          "statistics": ["Average"],      // CloudWatch statistics (list of strings)
          "period": 600,                // CloudWatch period (int)
          "cloudwatch_queries":         // (list of dictionaries)
          [   
            {
              "prefix": "Memory ",   // label prefix for associated data sets (string)
              "dimensions": { "InstanceId": "i-f361b7c4"}, // CloudWatch dimensions (dictionary)
              "region": "us-west-2"
            }
          ]
        };

        var network_in_qa = {  
          "namespace": "AWS/EC2",       // CloudWatch namespace (string)
          "metric": "NetworkIn",   // CloudWatch metric (string)
          "unit": "Bytes",            // CloudWatch unit (string)
          "statistics": ["Average"],      // CloudWatch statistics (list of strings)
          "period": 600,                // CloudWatch period (int)
          "cloudwatch_queries":         // (list of dictionaries)
          [   
            {
              "prefix": "Network In ",   // label prefix for associated data sets (string)
              "dimensions": { "InstanceId": "i-f361b7c4"}, // CloudWatch dimensions (dictionary)
              "region": "us-west-2"
            }
          ]
        };

        var network_out_qa = {  
          "namespace": "AWS/EC2",       // CloudWatch namespace (string)
          "metric": "NetworkOut",   // CloudWatch metric (string)
          "unit": "Bytes",            // CloudWatch unit (string)
          "statistics": ["Average"],      // CloudWatch statistics (list of strings)
          "period": 600,                // CloudWatch period (int)
          "cloudwatch_queries":         // (list of dictionaries)
          [   
            {
              "prefix": "Network Out ",   // label prefix for associated data sets (string)
              "dimensions": { "InstanceId": "i-f361b7c4"}, // CloudWatch dimensions (dictionary)
              "region": "us-west-2"
            }
          ]
        };


        var cpu_query = new google.visualization.Query('http://'+window.location.host+'/get_data?qs='+JSON.stringify(cpu_qa));
        cpu_query.send(function(response) {
          if (response.isError()) {
            alert('CloudWatch query: ' + response.getMessage() + ' ' + response.getDetailedMessage());
            return;
          }
      
          var data = response.getDataTable();
          var visualization = new google.visualization.AnnotatedTimeLine(document.getElementById('cpu_utilization'));
          visualization.draw(data, { 
            'allowRedraw': true, 
            'displayAnnotations': false, 
            'fill': 20,
            'legendPosition': 'newRow',
            'allValuesSuffix': '%'})
        });

        var mem_query = new google.visualization.Query('http://'+window.location.host+'/get_data?qs='+JSON.stringify(mem_qa));
        mem_query.send(function(response) {
          if (response.isError()) {
            alert('CloudWatch query: ' + response.getMessage() + ' ' + response.getDetailedMessage());
            return;
          }
      
          var data = response.getDataTable();
          var visualization = new google.visualization.AnnotatedTimeLine(document.getElementById('mem_utilization'));
          visualization.draw(data, {   
            'allowRedraw': true,
            'displayAnnotations': false, 
            'fill': 20,
            'legendPosition': 'newRow',
            'allValuesSuffix': '%'})
        });

        var network_in_query = new google.visualization.Query('http://'+window.location.host+'/get_data?qs='+JSON.stringify(network_in_qa));
        network_in_query.send(function(response) {
          if (response.isError()) {
            alert('CloudWatch query: ' + response.getMessage() + ' ' + response.getDetailedMessage());
            return;
          }
      
          var data = response.getDataTable();
          var visualization = new google.visualization.AnnotatedTimeLine(document.getElementById('network_in'));
          visualization.draw(data, {   
            'allowRedraw': true,
            'displayAnnotations': false, 
            'fill': 20,
            'legendPosition': 'newRow',
            'allValuesSuffix': 'Bytes'})
        });

        var network_out_query = new google.visualization.Query('http://'+window.location.host+'/get_data?qs='+JSON.stringify(network_out_qa));
        network_out_query.send(function(response) {
          if (response.isError()) {
            alert('CloudWatch query: ' + response.getMessage() + ' ' + response.getDetailedMessage());
            return;
          }
      
          var data = response.getDataTable();
          var visualization = new google.visualization.AnnotatedTimeLine(document.getElementById('network_out'));
          visualization.draw(data, {   
            'allowRedraw': true,
            'displayAnnotations': false, 
            'fill': 20,
            'legendPosition': 'newRow',
            'allValuesSuffix': 'Bytes'})
        });
      }
      
      google.setOnLoadCallback(drawVisualizations);
      setInterval('drawVisualizations()', 60000);

      $(function() {
        // handle clicks of the 'apply' button for the profiles.
        $('.netscaler-profiles .profile-apply button').on('click', function() {
          var clicked_li = $(this).closest('li.profile');
          var profile = $(clicked_li).attr('id');
          $.ajax('/apply_netscaler_profile?profile='+profile, {
            beforeSend: function(jqXHR, settings) {
              $(clicked_li).find('.profile-apply button').addClass('loading').html('<img src="/static/images/ajax-loader-sml.gif" />');
            },
            success: function(data, textStatus, jqXHR) {
              var active_li = $(clicked_li).siblings('.active');
              $(active_li).find('.profile-apply button').removeAttr('disabled').text('Apply');
              $(active_li).removeClass('active');

              $(clicked_li).find('.profile-apply button').removeClass('loading').attr('disabled','disabled').text('Active');
              $(clicked_li).addClass('active');
            },
            error: function(jqXHR, textStatus, errorThrown) {
              $(clicked_li).find('.profile-apply button').removeClass('loading').text('Apply');
            }
          });
        });

      });
    </script>
	</head>
	<body>
    <div id="wrapper">

      <div id="content">
        <div class="section-header">Control Panel</div>
        Understand the correlation between different Netscaler configurations and your AWS resource usage.
      </div>

      <div id="controls">
        <div class="netscaler">
          <div class="section-header">Netscaler</div>
          <div class="control-desc">
            Modify how the NetScaler delivers the content.
          </div>
          <ul class="netscaler-profiles">
            <li id="profile-1" class="profile active">
                <div class="profile-name">Load Balancing</div>
                <div class="profile-desc">Basic load balancing - a virtual server bound to a set of backend servers with default health monitors and a simple LB metric, like least connections</div>
                <div class="profile-apply"><button disabled>Active</button></div
            </li>
            <li id="profile-2" class="profile">
                <div class="profile-name">Acceleration</div>
                <div class="profile-desc">Server acceleration - basic LB + TCP multi-plexing + content caching</div>
                <div class="profile-apply"><button>Apply</button></div>
            </li>
            <li id="profile-3" class="profile">
                <div class="profile-name">Switching</div>
                <div class="profile-desc">L7 switching - switching based on a specific HTTP header fields (eg: URL, cookie or user-agent)</div>
                <div class="profile-apply"><button>Apply</button></div>
            </li>
            <li id="profile-4" class="profile">
                <div class="profile-name">Optimization</div>
                <div class="profile-desc">Content optimization including compression</div>
                <div class="profile-apply"><button>Apply</button></div>
            </li>
          </ul>
          <div class="control-footer">Go to the <a href="#">Netscaler Config</a></div>
        </div>
        <div class="clear"> </div>
        <div class="section-footer">It will take a few minutes for the graphs to reflect config changes.</div>
      </div>
      

      <div id="graphs">
        <div class="section-header">AWS Resource Usage</div>
        <div class="refresh-wrapper">refreshing in <span class="refresh-in">60</span></div>
        <div class="left">
          <div id="cpu_utilization" style="width: 500px; height: 300px;"></div>
          <div id="mem_utilization" style="width: 500px; height: 300px;"></div>
        </div>
        <div class="right">
          <div id="network_in" style="width: 500px; height: 300px;"></div>
          <div id="network_out" style="width: 500px; height: 300px;"></div>
        </div>
        <div class="clear"> </div>
      </div>

    </div>
  </body>
</html>
            