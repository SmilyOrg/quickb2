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

package QuickB2.debugging.drawing
{
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class qb2_debugDrawFlags 
	{
		public static const OUTLINES:uint          = 0x00000001;
		public static const FILLS:uint             = 0x00000002;
		public static const CIRCLE_SPOKE_1:uint    = 0x00000004;
		public static const CIRCLE_SPOKE_2:uint    = 0x00000008;
		public static const CIRCLE_SPOKE_3:uint    = 0x00000010;
		public static const CIRCLE_SPOKE_4:uint    = 0x00000020;
		public static const CENTROIDS:uint         = 0x00000040;
		public static const BOUND_BOXES:uint       = 0x00000080;
		public static const BOUND_CIRCLES:uint     = 0x00000100;
		public static const JOINTS:uint            = 0x00000200;
		public static const POSITIONS:uint         = 0x00000400;
		public static const VERTICES:uint          = 0x00000800;
		public static const FRICTION_Z_POINTS:uint = 0x00001000;
		public static const DECOMPOSITION:uint     = 0x00002000;
		
		public static const CIRCLE_SPOKES:uint   = CIRCLE_SPOKE_1 | CIRCLE_SPOKE_2 | CIRCLE_SPOKE_3 | CIRCLE_SPOKE_4;
	}
}