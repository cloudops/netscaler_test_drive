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

        % for webserver in webservers:
        var {{webserver['id'].replace('-','_')}}_cpu_qa = {  
          "namespace": "AWS/EC2",       // CloudWatch namespace (string)
          "metric": "CPUUtilization",   // CloudWatch metric (string)
          "unit": "Percent",            // CloudWatch unit (string)
          "statistics": ["Average"],      // CloudWatch statistics (list of strings)
          "period": 600,                // CloudWatch period (int)
          "cloudwatch_queries":         // (list of dictionaries)
          [   
            {
              "prefix": "CPU ",   // label prefix for associated data sets (string)
              "dimensions": { "InstanceId": "{{webserver['id']}}"} // CloudWatch dimensions (dictionary)
            }
          ]
        };

        //var {{webserver['id'].replace('-','_')}}_mem_qa = {  
        //  "namespace": "System/Linux",       // CloudWatch namespace (string)
        //  "metric": "MemoryUtilization",   // CloudWatch metric (string)
        //  "unit": "Percent",            // CloudWatch unit (string)
        //  "statistics": ["Average"],      // CloudWatch statistics (list of strings)
        //  "period": 600,                // CloudWatch period (int)
        //  "cloudwatch_queries":         // (list of dictionaries)
        //  [   
        //    {
        //      "prefix": "Memory ",   // label prefix for associated data sets (string)
        //      "dimensions": { "InstanceId": "{{webserver['id']}}"} // CloudWatch dimensions (dictionary)
        //    }
        //  ]
        //};

        var {{webserver['id'].replace('-','_')}}_network_in_qa = {  
          "namespace": "AWS/EC2",       // CloudWatch namespace (string)
          "metric": "NetworkIn",   // CloudWatch metric (string)
          "unit": "Bytes",            // CloudWatch unit (string)
          "statistics": ["Average"],      // CloudWatch statistics (list of strings)
          "period": 600,                // CloudWatch period (int)
          "cloudwatch_queries":         // (list of dictionaries)
          [   
            {
              "prefix": "Network In ",   // label prefix for associated data sets (string)
              "dimensions": { "InstanceId": "{{webserver['id']}}"} // CloudWatch dimensions (dictionary)
            }
          ]
        };

        var {{webserver['id'].replace('-','_')}}_network_out_qa = {  
          "namespace": "AWS/EC2",       // CloudWatch namespace (string)
          "metric": "NetworkOut",   // CloudWatch metric (string)
          "unit": "Bytes",            // CloudWatch unit (string)
          "statistics": ["Average"],      // CloudWatch statistics (list of strings)
          "period": 600,                // CloudWatch period (int)
          "cloudwatch_queries":         // (list of dictionaries)
          [   
            {
              "prefix": "Network Out ",   // label prefix for associated data sets (string)
              "dimensions": { "InstanceId": "{{webserver['id']}}"} // CloudWatch dimensions (dictionary)
            }
          ]
        };


        var {{webserver['id'].replace('-','_')}}_cpu_query = new google.visualization.Query('http://'+window.location.host+'/get_data?qs='+JSON.stringify({{webserver['id'].replace('-','_')}}_cpu_qa));
        {{webserver['id'].replace('-','_')}}_cpu_query.send(function(response) {
          if (response.isError()) {
            alert('CloudWatch query: ' + response.getMessage() + ' ' + response.getDetailedMessage());
            return;
          }
      
          var data = response.getDataTable();
          var visualization = new google.visualization.AnnotatedTimeLine(document.getElementById("{{webserver['id'].replace('-','_')}}_cpu_utilization"));
          visualization.draw(data, { 
            'allowRedraw': true, 
            'displayAnnotations': false, 
            'fill': 20,
            'legendPosition': 'newRow',
            'allValuesSuffix': '%'})
        });

        /*var {{webserver['id'].replace('-','_')}}_mem_query = new google.visualization.Query('http://'+window.location.host+'/get_data?qs='+JSON.stringify({{webserver['id'].replace('-','_')}}_mem_qa));
        {{webserver['id'].replace('-','_')}}_mem_query.send(function(response) {
          if (response.isError()) {
            alert('CloudWatch query: ' + response.getMessage() + ' ' + response.getDetailedMessage());
            return;
          }
        
          var data = response.getDataTable();
          var visualization = new google.visualization.AnnotatedTimeLine(document.getElementById("{{webserver['id'].replace('-','_')}}_mem_utilization"));
          visualization.draw(data, {   
            'allowRedraw': true,
            'displayAnnotations': false, 
            'fill': 20,
            'legendPosition': 'newRow',
            'allValuesSuffix': '%'})
        });*/

        var {{webserver['id'].replace('-','_')}}_network_in_query = new google.visualization.Query('http://'+window.location.host+'/get_data?qs='+JSON.stringify({{webserver['id'].replace('-','_')}}_network_in_qa));
        {{webserver['id'].replace('-','_')}}_network_in_query.send(function(response) {
          if (response.isError()) {
            alert('CloudWatch query: ' + response.getMessage() + ' ' + response.getDetailedMessage());
            return;
          }
      
          var data = response.getDataTable();
          var visualization = new google.visualization.AnnotatedTimeLine(document.getElementById("{{webserver['id'].replace('-','_')}}_network_in"));
          visualization.draw(data, {   
            'allowRedraw': true,
            'displayAnnotations': false, 
            'fill': 20,
            'legendPosition': 'newRow',
            'allValuesSuffix': 'Bytes'})
        });

        var {{webserver['id'].replace('-','_')}}_network_out_query = new google.visualization.Query('http://'+window.location.host+'/get_data?qs='+JSON.stringify({{webserver['id'].replace('-','_')}}_network_out_qa));
        {{webserver['id'].replace('-','_')}}_network_out_query.send(function(response) {
          if (response.isError()) {
            alert('CloudWatch query: ' + response.getMessage() + ' ' + response.getDetailedMessage());
            return;
          }
      
          var data = response.getDataTable();
          var visualization = new google.visualization.AnnotatedTimeLine(document.getElementById("{{webserver['id'].replace('-','_')}}_network_out"));
          visualization.draw(data, {   
            'allowRedraw': true,
            'displayAnnotations': false, 
            'fill': 20,
            'legendPosition': 'newRow',
            'allValuesSuffix': 'Bytes'})
        });

        % end
      }
      
      google.setOnLoadCallback(drawVisualizations);
      setInterval('drawVisualizations()', 60000);

      $(function() {
        // set the initial profile.
        var initial_profile = '{{profile}}';
        $('.netscaler-profiles #'+initial_profile).addClass('active');
        $('.netscaler-profiles #'+initial_profile+' .profile-apply button').attr('disabled','disabled').text('Active');

        // handle clicks of the 'apply' button for the profiles.
        $('.netscaler-profiles .profile-apply button').on('click', function() {
          var clicked_li = $(this).closest('li.profile');
          var profile = $(clicked_li).attr('id');
          $.ajax('/apply_netscaler_profile?profile='+profile, {
            beforeSend: function(jqXHR, settings) {
              $(clicked_li).find('.profile-apply button').addClass('loading').html('<img src="/static/images/ajax-loader-sml.gif" />');
            },
            success: function(data, textStatus, jqXHR) {
              if (data['result'] == profile) {
                var active_li = $(clicked_li).siblings('.active');
                $(active_li).find('.profile-apply button').removeAttr('disabled').text('Apply');
                $(active_li).removeClass('active');

                $(clicked_li).find('.profile-apply button').removeClass('loading').attr('disabled','disabled').text('Active');
                $(clicked_li).addClass('active');

                $('.netscaler .notify').text('Successfully changed profile...');
                $('.netscaler .notify').removeClass('error').addClass('success').fadeIn();
              } else {
                $(clicked_li).find('.profile-apply button').removeClass('loading').text('Apply');
                $('.netscaler .notify').text('Failed to change profile...');
                $('.netscaler .notify').addClass('error').removeClass('success').fadeIn();
              }
            },
            error: function(jqXHR, textStatus, errorThrown) {
              $(clicked_li).find('.profile-apply button').removeClass('loading').text('Apply');
            },
            complete: function(jqXHR, textStatus) {
              setTimeout(function() {
                $('.netscaler .notify').fadeOut();
              }, 7000);
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
          <div class="notify" style="display:none;"></div>
          <ul class="netscaler-profiles">
            <li id="profile_1" class="profile">
                <div class="profile-name">Load Balancing</div>
                <div class="profile-desc">Basic load balancing - a virtual server bound to a set of backend servers with default health monitors and a simple LB metric, like least connections</div>
                <div class="profile-apply"><button>Apply</button></div
            </li>
            <li id="profile_2" class="profile">
                <div class="profile-name">Acceleration &amp; Optimization</div>
                <div class="profile-desc">Server acceleration - basic LB + content caching + compression</div>
                <div class="profile-apply"><button>Apply</button></div>
            </li>
            <li id="profile_3" class="profile">
                <div class="profile-name">Switching</div>
                <div class="profile-desc">L7 switching - server HTML pages from one server and images from the other</div>
                <div class="profile-apply"><button>Apply</button></div>
            </li>
          </ul>
          <div class="control-footer">
            Go to the <a href="/netscaler_redirect">Netscaler Config</a><br />
            <span class="notice">(requires FireFox or Safari for Java Applet functionality)</span>
          </div>
        </div>
        <div class="clear"> </div>
        <div class="section-footer">It will take a few minutes for the graphs to reflect config changes.</div>
      </div>
      

      <div id="graphs">
        <div class="section-header">AWS Resource Usage</div>
        <div class="refresh-wrapper">refreshing in <span class="refresh-in">60</span></div>
        % for i, webserver in enumerate(webservers):
          % if i % 2 == 0:
            <div class="left">
          % else:
            <div class="right">
          % end
            <div class="webserver_name">{{webserver['name']}}</div>
            <div id="{{webserver['id'].replace('-','_')}}_cpu_utilization" class="cpu_utilization" style="width: 500px; height: 300px;"></div>
            <!--<div id="{{webserver['id'].replace('-','_')}}_mem_utilization" class="mem_utilization" style="width: 500px; height: 300px;"></div>-->
            <div id="{{webserver['id'].replace('-','_')}}_network_in" class="network_in" style="width: 500px; height: 300px;"></div>
            <div id="{{webserver['id'].replace('-','_')}}_network_out" class="network_out" style="width: 500px; height: 300px;"></div>
          </div>
          % if i % 2 == 1:
            <div class="clear"> </div>
          % end
        % end
      </div>

    </div>
  </body>
</html>
            