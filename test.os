module zeta.testmodule;

class LexerState {
	def:string text;
	def:size_t position;
	def:string file;
	def:Appender:(Token[]) tokenBuffer;

	function this(def:string file, def:string text) {
		this.file = file;
		this.text = text;
	}

	@property function:bool empty() {
		a * b + c;
		a + b * c;
		return position >= text.length;
	}

	@property function:size_t length() {
		return text.length - position;
	}

	@property function:dchar front() {
		return text[position];
	}

	function:dchar popFront() {
		return text[position++];
	}

	function:string frontN(def:size_t amount) {
		return text[position .. min(position + amount, $)];
	}

	function:string popFrontN(def:size_t amount) {
		def result = this.frontN(amount);
		position += result.length;
		return result;
	}

	@property function:SourceLocation location() {
		return SourceLocation.fromBuffer(text, position, file);
	}

	function:void pushToken(def:Token token) {
		this.tokenBuffer.put(token);
	}

	@property function:Token[] tokens() {
		return this.tokenBuffer.data;
	}
}