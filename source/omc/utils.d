/* 
 * omc: The official Omicron compiler.
 * Reference implementation of the Omicron programming language.
 * Copyright (c) 2018-2021 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MPL-2.0 license (See LICENCE file).
 */
module omc.utils;

import std.range;

mixin template Visitor(IVisitor) {
	override void accept(IVisitor visitor) {
		visitor.visit(this);
	}
}

auto stealFront(Range)(Range range) {
	auto result = range.front;
	range.popFront();
	return result;
}

auto stealFrontN(Range)(Range range, size_t amount) {
	auto result = range.take(amount);
	range.popFrontN(amount);
	return result;
}

// mixin template MultiDispatch(string name) {
// 	mixin ("alias "~name ~" = payload;");
// 	auto payload(Arguments...)(Arguments arguments) {
// 		// static assert(0, typeof(this));
// 		static assert(0, __traits(getOverloads, typeof(this), name, true));
// 		static foreach(overload; __traits(getOverloads, typeof(this), name)) {
// 			static foreach(index, Paramater; Paramaters!overload) {
// 				static if(index >= Arguments.length) break;
// 				else static if (is(Paramater == Arguments[i]) || is(Arguments[i]: Paramater)) {
// 					return overload(cast(Paramaters!overload)arguments);
// 				}
// 			}
// 		}
// 		// static assert(0, "cannot find valid overload for " ~ name ~ Arguments.stringof);
// 	}
// }