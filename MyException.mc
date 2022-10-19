import Toybox.Lang;

module MyModule{
	(:Tools)
	module Tools{
		class MyException extends Lang.Exception {
			function initialize(msg as String) {
				Exception.initialize();
				self.mMessage = msg;
			}
		}
	}
}