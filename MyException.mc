using Toybox.Lang;

module MyModule{
	(:Tools)
	module Tools{
		class MyException extends Lang.Exception {
			function initialize(msg) {
				Exception.initialize();
				self.mMessage = msg;
			}
		}
	}
}