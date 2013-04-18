 1. Create a Facebook App. Specify a unique namespace.
 1. Go to Open Graph and click on Stories.
 1. Click on Stories, Create a New Story. Then create a Create action and Challenge object, then click the Create button.
 1. Grab this code.
 1. Open up the ViewController.m file in the code and substitute ''mobdevcon'' with your app namespace.
 1. Go to your app's .plist and change these values:
   
      + fbAPP_ID to ''fb'' followed by your Facebook app id.
      + FacebookAppID value to your app id's value.
      + FacebookDisplayName value to your app's Display Name in the Facebook App Dashboard.
