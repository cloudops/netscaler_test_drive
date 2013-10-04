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
            <li class="active">
                <div class="profile-name">Basic Config</div>
                <div class="profile-desc">Don't use any special features.  This is the most basic configuration of the NetScaler.</div>
                <div class="profile-apply"><button disabled>Active</button></div>
            </li>
            <li>
                <div class="profile-name">Featured Config</div>
                <div class="profile-desc">Take advantage of the NetScalers power by using Integrated Caching, Compression and more.</div>
                <div class="profile-apply"><button>Apply</button></div>
            </li>
            <li>
                <div class="profile-name">Advanced Config</div>
                <div class="profile-desc">Allow the NetScaler to dynamically update its config in order to optimize based on traffic patterns.</div>
                <div class="profile-apply"><button>Apply</button></div>
            </li>
          </ul>
          <div class="control-footer">Go to the <a href="#">Netscaler Config</a> or <a href="#">Action Analytics</a></div>
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
            