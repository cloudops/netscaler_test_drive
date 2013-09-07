<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <meta http-equiv="content-type" content="text/html; charset=utf-8"/>
    <title>{{title}}</title>
    <link rel="stylesheet" type="text/css" href="/static/css/iphone-toggle.css">
    <link rel="stylesheet" type="text/css" href="/static/css/style.css">
    <script src="/static/js/jquery-1.10.2.min.js"></script>
    <script type="text/javascript" src="/static/js/json2.js"></script>
    <script type="text/javascript" src="http://www.google.com/jsapi"></script>
    <script type="text/javascript">
        google.load('visualization', '1', {packages: ['annotatedtimeline']});
    </script>
    <script type="text/javascript">
        function drawVisualizations() {
          // "start_time" and "end_time" are already defined in config.py:
          //end_time = new Date;
          //start_time = new Date;
          //start_time.setDate(end_time.getDate()-1);
          //end_time.setDate(end_time.getDate());
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

        $(function() {
          setInterval('drawVisualizations()', 60000);

          var countdown = setInterval(function(){
            sec=parseInt($(".refresh-in").html()); 
            if (sec != 0) {
              $(".refresh-in").html(sec-1);
            } else { // countdown is finished, reset...
              $(".refresh-in").html(59);
            }
          },1000);

          var netscaler_timeout;
          $(".netscaler .iphone-toggle-buttons input").on('change', function(e) {
            clearTimeout(netscaler_timeout);
            netscaler_timeout = setTimeout(function() {
              var params = '';
              var inputs = $(".netscaler .iphone-toggle-buttons input");
              inputs.each(function(i, el) {
                var name = $(el).attr('name');
                var value = $(el).is(':checked');
                if (params == '') {
                  params += '?'+name+'='+value
                } else {
                  params += '&'+name+'='+value
                }
              });

              $.ajax('/netscaler_config'+params, {
                beforeSend: function(jqXHR, settings) {
                  $('.netscaler .status').show();
                  $('.netscaler .status .processing').fadeIn();
                  $('.netscaler .status .message').hide();
                },
                success: function(data, textStatus, jqXHR) {
                  console.log(data);
                  $('.netscaler .status .processing').fadeOut();
                  $('.netscaler .status .message').html("Config saved...");
                  $('.netscaler .status .message').fadeIn();
                },
                error: function(jqXHR, textStatus, errorThrown) {
                  console.log(jqXHR, textStatus, errorThrown);
                  $('.netscaler .status .processing').fadeOut();
                  $('.netscaler .status .message').html("Error: "+errorThrown);
                  $('.netscaler .status .message').fadeIn();
                },
                complete: function(jqXHR, textStatus) {
                  setTimeout(function() {
                    $('.netscaler .status').fadeOut();
                  }, 3000)
                }
              });
            }, 2000);
          });

          var loader_timeout;
          $(".loader .iphone-toggle-buttons input").on('change', function(e) {
            clearTimeout(loader_timeout);
            loader_timeout = setTimeout(function() {
              var params = '';
              var inputs = $(".loader .iphone-toggle-buttons input");
              inputs.each(function(i, el) {
                var name = $(el).attr('name');
                var value;
                if ($(el).attr('type') == 'checkbox') {
                  value = $(el).is(':checked');
                } else {
                  value = $(el).val();
                }
                if (params == '') {
                  params += '?'+name+'='+value
                } else {
                  params += '&'+name+'='+value
                }
              });

              $.ajax('/loader_config'+params, {
                beforeSend: function(jqXHR, settings) {
                  $('.loader .status').show();
                  $('.loader .status .processing').fadeIn();
                  $('.loader .status .message').hide();
                },
                success: function(data, textStatus, jqXHR) {
                  console.log(data);
                  $('.loader .status .processing').fadeOut();
                  $('.loader .status .message').html("Config saved...");
                  $('.loader .status .message').fadeIn();
                },
                error: function(jqXHR, textStatus, errorThrown) {
                  console.log(jqXHR, textStatus, errorThrown);
                  $('.loader .status .processing').fadeOut();
                  $('.loader .status .message').html("Error: "+errorThrown);
                  $('.loader .status .message').fadeIn();
                },
                complete: function(jqXHR, textStatus) {
                  setTimeout(function() {
                    $('.loader .status').fadeOut();
                  }, 3000)
                }
              });
            }, 2000);
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
        <div class="netscaler left">
          <div class="section-header">Netscaler</div>
          <div class="control-desc">
            Modify how the NetScaler delivers the content.
          </div>
          <div class="iphone-toggle-buttons">
            <ul>
              <li><label for="tcp_multiplexing">
                <input type="checkbox" name="tcp_multiplexing" id="tcp_multiplexing" />
                <span>TCP Multiplexing</span></label><span class="toggle-label">TCP Multiplexing</span></li>
              <li><label for="caching"><input type="checkbox" name="caching" id="caching" checked="checked" />
                <span>Caching</span></label><span class="toggle-label">Caching</span></li>
              <li><label for="compression"><input type="checkbox" name="compression" id="compression" checked="checked" />
                <span>Compression</span></label><span class="toggle-label">Compression</span></li>
              <li class="status">
                <div class="processing"><span class="loader">&nbsp;</span><span class="loader-text">Updating config...</span></div>
                <div class="message"></div>
              </li>
            </ul>
          </div>
          <div class="control-footer">Go to the <a href="#">Netscaler Config</a> or <a href="#">Action Analytics</a></div>
        </div>
        <div class="loader right">
          <div class="section-header">Load Generator</div>
          <div class="control-desc">
            Modify how the load is generated.
          </div>
          <div class="iphone-toggle-buttons">
            <ul>
              <li><label for="jitter">
                <input type="checkbox" name="jitter" id="jitter" checked="checked" />
                <span>Jitter</span></label>
                <input type="text" class="rate" name="jitter_rate" value="10" /> <span class="rate-label">%</span>
                <span class="toggle-label">Jitter</span></li>
              <li><label for="drop_packets"><input type="checkbox" name="drop_packets" id="drop_packets" />
                <span>Drop Packets</span></label>
                <input type="text" class="rate" name="packet_drop_rate" value="5" /> <span class="rate-label">%</span>
                <span class="toggle-label">Drop Packets</span></li>
              <li><label for="tcp_latency"><input type="checkbox" name="tcp_latency" id="tcp_latency" checked="checked" />
                <span>TCP Latency</span></label>
                <input type="text" class="rate" name="tcp_latency_rate" value="15" /> <span class="rate-label">%</span>
                <span class="toggle-label">TCP Latency</span></li>
              <li class="status">
                <div class="processing"><span class="loader">&nbsp;</span><span class="loader-text">Updating config...</span></div>
                <div class="message"></div>
              </li>
            </ul>
          </div>
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
            