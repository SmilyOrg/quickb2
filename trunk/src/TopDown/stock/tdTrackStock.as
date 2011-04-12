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

package TopDown.stock 
{
	import As3Math.geo2d.*;
	import QuickB2.objects.*;
	import TopDown.ai.*;
	
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class tdTrackStock 
	{
		public static function newTrackRect(center:amPoint2d, width:Number, height:Number, extraWidth:Number = 0, extraHeight:Number = 0, clockwise:Boolean = true, speedLimit:Number = 13.5):Vector.<qb2Object>
		{
			var widDiv2:Number = width / 2;
			var heiDiv2:Number = height / 2;
			
			var track1:tdTrack = new tdTrack(center.clone().incX(-widDiv2-extraWidth).incY(-heiDiv2), center.clone().incX(widDiv2+extraWidth).incY(-heiDiv2));
			var track2:tdTrack = new tdTrack(center.clone().incX(widDiv2).incY(-heiDiv2-extraHeight), center.clone().incX(widDiv2).incY(heiDiv2+extraHeight));
			var track3:tdTrack = new tdTrack(center.clone().incX(widDiv2+extraWidth).incY(heiDiv2), center.clone().incX(-widDiv2-extraWidth).incY(heiDiv2));
			var track4:tdTrack = new tdTrack(center.clone().incX( -widDiv2).incY(heiDiv2 + extraHeight), center.clone().incX( -widDiv2).incY( -heiDiv2 - extraHeight));
			
			var tracks:Vector.<qb2Object> = Vector.<qb2Object>([track1, track2, track3, track4]);
			
			for (var i:int = 0; i < tracks.length; i++) 
			{
				var track:tdTrack = tracks[i] as tdTrack;
				
				if ( !clockwise )
				{
					track.flip();
				}
				
				track.speedLimit = speedLimit;
			}
			
			return tracks;
		}
	}
}