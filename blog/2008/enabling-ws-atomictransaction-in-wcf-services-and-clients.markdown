Date: 2008-06-18  
Tags: Transactions, WCF, Web Services  

# Enabling WS-AtomicTransaction in WCF services and clients

Support for all the WS-* standards is built into WCF and doesn't require any complex code to get working, but like all things in the WCF world does require a fair bit of attribution and configuration before it all hangs together. It took me a while to work out exactly which combination of bindings and behaviours and attributes would get transaction flow working between two WCF endpoints, so to save you some time (and me in the future when I forget) here's exactly what you need to do.

Note that this isn't the only way to get transactions working as you can set the services up entirely using code or mostly using configuration, but it's a reasonable starting point that demonstrates the use of both.

For an example service I've chosen a very basic messaging interface, as message delivery between machines is the sort of thing you might want to make transactional. It's attributed in the same way as any other service contract, with the addition of a `TransactionFlowAttribute` indicating that transactions are `Mandatory` for the service interface; you could also use `Allowed` to permit it to be called without a transaction. This attribute must be applied to the contract because without it the transaction flow option defaults to `NotAllowed`.

~~~ csharp
[ServiceContract(Namespace = "http://services.company.com/v1/messagingservice/")]
public interface IMessagingService
{
    [OperationContract]
    [TransactionFlow(TransactionFlowOption.Mandatory)]
    void SubmitMessage(
        [MessageParameter(Name = "MessageData")] byte[] messageData,
        [MessageParameter(Name = "Priority")] int priority);
}
~~~

The final step on the server side is to configure the behaviour and bindings for the service in the application configuration file. Although the behaviour section isn't strictly necessary for transaction flow, I've left it in as you usually want to enable metadata exchange (at least during the development phase) and it makes it much easier to add a service reference from the client later. The key line in the configuration is the custom `wsHttpBinding` which permits transaction flow.

~~~ xml
<system.serviceModel>
  <behaviors>
    <serviceBehaviors>
      <behavior name="MessagingServiceBehavior">
        <serviceMetadata httpGetEnabled="true" />
      </behavior>
    </serviceBehaviors>
  </behaviors>
  <bindings>
    <wsHttpBinding>
      <binding name="TransactionalWsHttpBinding" transactionFlow="true"/>
    </wsHttpBinding>
  </bindings>
  <services>
    <service name="MessagingService" behaviorConfiguration="MessagingServiceBehavior">
      <endpoint
        address=""
        binding="wsHttpBinding"
        bindingConfiguration="TransactionalWsHttpBinding"
        contract="MessagingServer.IMessagingService"
        bindingNamespace="http://services.company.com/v1/messagingservice/"/>
      <endpoint
        address="mex"
        binding="mexHttpBinding"
        contract="IMetadataExchange" />
    </service>
  </services>
</system.serviceModel>
~~~

And with that, we have transaction flow over a WS-AtomicTransaction web service. It does take a few steps to set up, but it's all declarative and quite prescriptive once you work out what combination of attributes and configuration is needed. Anybody who has worked with WSE in the past will appreciate how much easier this is! And the great thing is that it works with `TransactionScope` so you don't need to change your programming model.

Note that if you add more services then you can re-use the behaviours and bindings for them too; just delete the binding/behaviour elements that the WCF designer puts in the config files and point them at the existing ones. This makes it much easier to manage the services and keep their behaviour consistent.