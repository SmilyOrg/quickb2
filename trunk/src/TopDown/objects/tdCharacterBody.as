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

package TopDown.objects 
{
	import As3Math.geo2d.*;
	
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class tdCharacterBody extends tdSmartBody
	{
		public static const FACING_LAST:int  = 0;
		public static const FACING_LEFT:int  = 1;
		public static const FACING_RIGHT:int = 2;
		public static const FACING_UP:int    = 4;
		public static const FACING_DOWN:int  = 8;
		
		public var speedCap:Number = 15;
		
		public function tdCharacterBody() 
		{
			hasFixedRotation = true;
		}
		
		protected override function update():void
		{
			super.update();
			
			var forwardBack:Number = brainPort.NUMBER_PORT_1;
			var leftRight:Number   = brainPort.NUMBER_PORT_2;
			
			var direction:amVector2d = new amVector2d(leftRight, forwardBack);
			if ( direction.length > speedCap )  direction.setLength(speedCap);
			this.linearVelocity.copy(direction);
		}
	}
}