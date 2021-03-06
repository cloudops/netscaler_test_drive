<?xml version="1.0" encoding="UTF-8"?>
<template_deployment>
  <template_info>
    <application_name>profile_deployment</application_name>
    <templateversion_major/>
    <templateversion_minor/>
    <author/>
    <introduction/>
    <summary/>
    <version_major>10</version_major>
    <version_minor>1</version_minor>
    <build_number>121.14</build_number>
  </template_info>
  <appendpoint_list>
    <appendpoint>
      <ipv46>{{netscaler_vip}}</ipv46>
      <port>80</port>
      <servicetype>HTTP</servicetype>
    </appendpoint>
  </appendpoint_list>
  <service_list>
    <service>
      <ip>{{webserver_1_ip}}</ip>
      <port>80</port>
      <servicetype>HTTP</servicetype>
    </service>
    <service>
      <ip>{{webserver_2_ip}}</ip>
      <port>80</port>
      <servicetype>HTTP</servicetype>
    </service>
  </service_list>
  <servicegroup_list/>
</template_deployment>