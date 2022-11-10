---
languages:
- csharp
products:
- azure
- azure-service-fabric
page_type: sample
description: "The quickstart contains an application with multiple services demonstrating the concepts of service communication and use of reliable dictionaries, in conjunction with Datadog installation."
---

# Service Fabric .NET Tracer Quickstart
This repository contains an quickstart project for [Microsoft Azure Service Fabric](https://azure.microsoft.com/services/service-fabric/). The quickstart project contains a single application with multiple services demonstrating the basic concepts of service communication and use of reliable dictionaries.

For a guided tour with the quickstart:
[Service Fabric .NET quickstart](https://docs.microsoft.com/en-us/azure/service-fabric/service-fabric-quickstart-dotnet)

More info on Service Fabric:
 - [Documentation](https://docs.microsoft.com/azure/service-fabric/)
 - [Service Fabric sample projects](https://azure.microsoft.com/resources/samples/?service=service-fabric)
 - [Service Fabric open source home repo](https://github.com/azure/service-fabric)
 
This guide does not include how-to on setting up and configuring an Azure Service Fabric Cluster.
 
## Create a Service Fabric application

![Create a Service Fabric project](https://user-images.githubusercontent.com/1801443/93098850-5079fd80-f675-11ea-90d6-7573b7faef68.png)

Start with a stateless ASP.NET Core application, and use MVC as a template.

![Create a stateleess ASP.NET Core application](https://user-images.githubusercontent.com/1801443/93099063-959e2f80-f675-11ea-805c-eb627e2b9e53.png)

## Setting up the Datadog Agent

Add a new Service Fabric Service to the solution.

![Add new Service Fabric Service](https://user-images.githubusercontent.com/1801443/93102030-04c95300-f679-11ea-89f2-1de6160b5bc2.png)

![Setup the agent container](https://user-images.githubusercontent.com/1801443/93107331-73111400-f67f-11ea-9a5e-06094e775177.png)

Replace the `ServiceManifest.xml` with this:

```
<?xml version="1.0" encoding="utf-8"?>
<ServiceManifest Name="DatadogAgentPkg" Version="1.0.0" xmlns="http://schemas.microsoft.com/2011/01/fabric" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <ServiceTypes>
    <StatelessServiceType ServiceTypeName="DatadogAgentType" UseImplicitHost="true" />
  </ServiceTypes>
  <CodePackage Name="Code" Version="1.0.0">
    <EntryPoint>
      <ContainerHost>
        <ImageName>datadog/agent</ImageName>
      </ContainerHost>
    </EntryPoint>
    <EnvironmentVariables>
      <EnvironmentVariable Name="DD_API_KEY" Value="API_KEY_GOES_HERE"/>
      <EnvironmentVariable Name="DD_ENV" Value="apm-reliability-testing"/>
      <EnvironmentVariable Name="DD_APM_ENABLED" Value="true"/>
      <EnvironmentVariable Name="DD_APM_NON_LOCAL_TRAFFIC" Value="true"/>
      <EnvironmentVariable Name="DD_DOGSTATSD_NON_LOCAL_TRAFFIC" Value="true"/>
      <EnvironmentVariable Name="DD_HEALTH_PORT" Value="5002"/>
    </EnvironmentVariables>
  </CodePackage>
  <ConfigPackage Name="Config" Version="1.0.0" />
  <Resources>
    <Endpoints>
      <Endpoint Name="DatadogTypeEndpoint" UriScheme="http" Port="5002" Protocol="http"/>
      <Endpoint Name="DatadogTraceEndpoint" UriScheme="http" Port="8126" Protocol="http"/>
      <Endpoint Name="DatadogStatsEndpoint" UriScheme="udp" Port="8125" Protocol="udp"/>
    </Endpoints>
  </Resources>
</ServiceManifest>
```

Add the corresponding port bindings to the `ServiceManfestImport` section in `ApplicationManifest.xml`:

```
  <ServiceManifestImport>
    <ServiceManifestRef ServiceManifestName="DatadogAgentPkg" ServiceManifestVersion="1.0.0" />
    <ConfigOverrides />
    <Policies>
      <ContainerHostPolicies CodePackageRef="Code">
        <PortBinding ContainerPort="5002" EndpointRef="DatadogTypeEndpoint" />
        <PortBinding ContainerPort="8126" EndpointRef="DatadogTraceEndpoint" />
        <PortBinding ContainerPort="8125" EndpointRef="DatadogStatsEndpoint" />
      </ContainerHostPolicies>
    </Policies>
  </ServiceManifestImport>
```

## Installing the .NET Tracer

Installing the tracer requires machine administrator permissions.
Add the `SetupAdminUser` to the `Principals` section in `ApplicationManifest.xml`. If the `Principals` section is missing, add it.

```
  <Principals>
    <Users>
      <User Name="SetupAdminUser">
        <MemberOf>
          <SystemGroup Name="Administrators" />
        </MemberOf>
      </User>
    </Users>
  </Principals>
```

In the `ServiceManifestImport` section of the service responsible for deploying the tracer to the cluster, set `SetupAdminUser` as the executing user for the `Setup` script.

```
  <ServiceManifestImport>
    <ServiceManifestRef ServiceManifestName="ServiceThatDeploysDatadogTracerPkg" ServiceManifestVersion="1.0.0" />
    <ConfigOverrides />
    <Policies>
      <RunAsPolicy CodePackageRef="Code" UserRef="SetupAdminUser" EntryPointType="Setup" />
    </Policies>
  </ServiceManifestImport>
```  

In the `ServiceManifest.xml` of the service responsible for deploying the tracer, add the reference to the install script:

```
  <CodePackage Name="Code" Version="1.0.0">
    <SetupEntryPoint>
      <ExeHost>
        <Program>DatadogInstall.bat</Program>
        <WorkingFolder>CodePackage</WorkingFolder>
      </ExeHost>
    </SetupEntryPoint>
    <EntryPoint>
      <ExeHost>
        <Program>ServiceThatDeploysDatadogTracer.exe</Program>
        <WorkingFolder>CodePackage</WorkingFolder>
      </ExeHost>
    </EntryPoint>
  </CodePackage>
```

Include the `DatadogInstall.bat` and `DatadogInstall.ps1` scripts in the project responsible for deploying the tracer.
In the file properties of both scripts, set them to be copied to the output directory.

![Copy to output directory](https://user-images.githubusercontent.com/1801443/93110062-d05a9480-f682-11ea-8fb4-7b266f576f68.png)

The latest representation of this install process is here: https://github.com/DataDog/dd-trace-dotnet-asf-sample/tree/master/VotingWeb
 - [Batch Script](https://github.com/DataDog/dd-trace-dotnet-asf-sample/blob/master/VotingWeb/DatadogInstall.bat)
 - [Powershell Script](https://github.com/DataDog/dd-trace-dotnet-asf-sample/blob/master/VotingWeb/DatadogInstall.ps1)

---
