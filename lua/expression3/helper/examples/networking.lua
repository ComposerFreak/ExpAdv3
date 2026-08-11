/***********************************************************************************
    E3 - Networking

    The server and each client are separate programs. Networking is how they
    send information to each other. You build a message into a 'stream', write
    values into it, then send it. The other side reads those values back out
    IN THE SAME ORDER they were written.
***********************************************************************************/
@name "E3 - Networking";

/*
    server { } runs only on the server.
    client { } runs only on each client.
    A single gate can contain both, which is exactly what networking needs.
*/

server {
    // Two seconds after the gate starts, tell every client hello.
    timer.simple(2, function() {

        // net.start(name) begins a message and returns a stream to write into.
        stream msg = net.start("greeting");

        // Write the values. Order matters - the client reads them back the same way.
        msg.writeString("Hello from the server!");
        msg.writeFloat(time.curtime());

        // net.sendToClients(stream) sends it to everyone.
        net.sendToClients(msg);
    });

    // The server also listens for "ping" messages coming back from clients.
    net.receive("ping", function(stream msg) {
        string who = msg.readString();
        system.print("Server received a ping from: ", who);
    });
}

client {
    // net.receive(name, callback) runs whenever a message with that name arrives.
    net.receive("greeting", function(stream msg) {

        // Read the values back in the SAME order the server wrote them.
        string text = msg.readString();
        number when = msg.readFloat();

        system.print("Client got: ", text, " (sent at ", math.round(when), ")");
    });

    // Send a message the other way, from client to server, once on startup.
    timer.simple(3, function() {
        player me = system.getClient();
        stream msg = net.start("ping");
        msg.writeString(me.name());
        net.sendToServer(msg);
    });
}
