class Discord
{
private:
    string m_webhookUrl; // Discord webhook URL

public:
    // Constructor to initialize the webhook URL
    Discord(string webhookUrl)
    {
        m_webhookUrl = webhookUrl;
    }

    // Function to send a message to Discord
    void sendMessage(string message)
    {
        uchar data[];
        string postData = "{\"content\":\"" + message + "\"}";
        string header;
        char result[];
        int res=WebRequest("POST", m_webhookUrl, postData,5000,data,result,header);

        // Check the result and handle any errors
        if (res != 200)
        {
            Print("Failed to send message to Discord. HTTP response code: ", res);

            // Log the error to a file if needed
             FileWrite("DiscordError.log", TimeToString(TimeCurrent()) + ": Failed to send message to Discord. HTTP response code: " + IntegerToString(res));
        }
        else
        {
            Print("Message sent successfully to Discord.");

            // Log the successful message to a file if needed
          FileWrite("DiscordSuccess.log", TimeToString(TimeCurrent()) + ": Message sent successfully to Discord.");
        }
    }
};
