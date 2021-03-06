/* Security.vcl hanlders VCL file
 * Copyright (C) 2009 Kacper Wysocki
 * 
 * **************** handlers **************** *
 * The rest of the code assumes this file defines the
 * following:
 *   sec_honey   - the honeyput backend
 *   sec_log     - logging function
 *   sec_handler - this function handles all triggered rules
 *
 * If you do not intend on changing these there is no need to read on.
 */

sub sec_default_handler {
   # swap this one with your handler (see below)
   call sec_reject;
}

/* the honeypot backend... 
 * presently defined to give no service
 * possible uses:
 *   send to less critical server
 *   log evil traffic
 *   sandbox request
 *   execute CGI scripts based on traffic
 *   ... ie to firewall client
 *   ... other active responses?
 */
backend sec_honey {
   .host = "127.0.1.2";
   .port = "3";
}

# Here you can specify what gets logged when a rule triggers.
sub sec_log {
         log "security.vcl "
             "Rule:" req.http.X-SEC-Module "-" req.http.X-SEC-RuleId 
             " xid:" req.xid " " req.http.X-SEC-Client ;
}


/* You can define how to handle the different severity levels. */
sub sec_handler {
   ## magichandler handles restarts should always be called!
   call sec_magichandler;

   if(req.http.X-SEC-Severity == "1"){
      /* we have only one severity for now: this is the default rule */
      call sec_default_handler;
   }else{
      # fallback attack response when severity is off the charts
      call sec_default_handler;
   }

   if(!req.http.X-SEC-Client){ # this variable always present, so rule always false
      # all functions must be used in vcl, fool compiler by putting them here

      log "security.vcl WONTREACH: available sec handlers";
      #  the handlers are defined in main.vcl along with the error codes
      #     handler name  # code # purpose
      call sec_general;   # 800  # debug handler - delivers X-SEC-Rule to client
      call sec_reject;    # 801  # 403 reject with message
      call sec_redirect;  # 802  # 302 redirect
      call sec_honeypot;  # 803  # restart request with honeypot backend
      call sec_synthtml;  # 804  # synthesize a response
      call sec_drop;      # 805  # drop the request (not implemented) 
      call sec_myhandler; # any  # do your own thing

      ## note! the passthru handler really does pass thru
      # - you must make sure it is the last thing called
      call sec_passthru;  # n/a  # log client and pass thru to default error logic
   }
}

/* You can define your own handlers here if you know a little vcl.
 * The default handlers are defined in main.vcl
 * remember that it must be referenced in the code above */

/* sample handler, contains sample code for all handler types */
sub sec_myhandler {
   # perform an action based on the error code as above.

   error 800 "Blahblah";

   set req.http.X-SEC-Response = "we don't like your kind around here";
   error 801 "Rejected";

   set req.http.X-SEC-Response = "http://u.rdir.it/hit/me/please";
   error 802 "Redirect";

   # send to sec_honey backend
   error 803 "Honeypot me";

   set req.http.X-SEC-Response = "<h1>Whatever</h1> so you think you can dance?";
   error 804 "Synthesize";

   error 805 "Drop";
}
