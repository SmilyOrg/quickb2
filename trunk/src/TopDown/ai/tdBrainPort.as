/**
 * Copyright (c) 2010 Johnson Center for Simulation at Pine Technical College
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

package TopDown.ai
{
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public final class tdBrainPort
	{
		/// Usually forward/back (1.0 to -1.0).
		public var NUMBER_PORT_1:Number = 0;
		
		/// Usually left/right (-1.0 to 1.0).
		public var NUMBER_PORT_2:Number = 0;
		
		/// Brake for cars (0.0 to 1.0).
		public var NUMBER_PORT_3:Number = 0;
		
		public var NUMBER_PORT_4:Number = 0;
		
		// For shifting in cars.
		public var INTEGER_PORT_1:int = 0;
		
		/// N, S, E, or W facing for character bodies from keyboard input (tdCharacterBody.FACING_*).  This only has graphical implications.
		public var INTEGER_PORT_2:int = 0;
		
		/// Facing from mouse input.
		public var INTEGER_PORT_3:int = 0;
		public var INTEGER_PORT_4:int = 0;
		
		/// Run toggle for characters.
		public var BOOLEAN_PORT_1:Boolean = false;
		public var BOOLEAN_PORT_2:Boolean = false;
		public var BOOLEAN_PORT_3:Boolean = false;
		public var BOOLEAN_PORT_4:Boolean = false;
		
		public var STRING_PORT:String = "";
		
		public var BITMASK_PORT:uint  = 0;
		
		public var open:Boolean = true;
		
		public function clear():void
		{
			BOOLEAN_PORT_1 = false;
			BOOLEAN_PORT_2 = false;
			BOOLEAN_PORT_3 = false;
			BOOLEAN_PORT_4 = false;
			
			INTEGER_PORT_1 = 0;
			INTEGER_PORT_2 = 0;
			INTEGER_PORT_3 = 0;
			INTEGER_PORT_4 = 0;
			
			NUMBER_PORT_1 = 0;
			NUMBER_PORT_2 = 0;
			NUMBER_PORT_3 = 0;
			NUMBER_PORT_4 = 0;
			
			STRING_PORT = "";
			
			BITMASK_PORT = 0;
		}
	}
}