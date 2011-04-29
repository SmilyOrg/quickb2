package demos 
{
	import As3Math.geo2d.amPoint2d;
	import As3Math.geo2d.amVector2d;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import QuickB2.debugging.drawing.qb2_debugDrawSettings;
	import QuickB2.objects.tangibles.qb2Body;
	import QuickB2.stock.qb2SoftPoly;
	import QuickB2.stock.qb2Stock;
	import As3Math.consts.RAD_15;
	import surrender.srGraphics2d;
	
	/**
	 * Simple demo showing how to use the qb2Tangible::distanceTo() function.  Also how you can override functions
	 * to handle game-loop code, instead of using event listeners, like most of the other demos here do.
	 * 
	 * @author Doug Koellmer
	 */
	public class Distance extends Demo
	{
		private var jello:qb2SoftPoly = qb2Stock.newCircleSoftPoly(new amPoint2d(stageWidth / 3, stageHeight / 2), 50);
		private var rect:qb2Body      = qb2Stock.newRoundedRectBody(new amPoint2d(stageWidth * (2 / 3), stageHeight / 2), 100, 50, 10, 1, RAD_15);
		
		public function Distance() 
		{
			addObject(jello, rect);
		}
		
		private var pointA:amPoint2d  = new amPoint2d();
		private var pointB:amPoint2d  = new amPoint2d();
		private var vector:amVector2d = new amVector2d();
		
		protected override function update():void
		{
			super.update();
			
			//--- This function optionally outputs the vector and points describing the smallest distance between the two objects.
			jello.distanceTo(rect, vector, pointA, pointB);
		}
		
		public override function drawDebug(graphics:srGraphics2d):void
		{
			super.drawDebug(graphics);
			
			var distanceColor:uint = 0xff0000;
			graphics.setLineStyle(0, 0, 0);
			graphics.beginFill(distanceColor, qb2_debugDrawSettings.fillAlpha);
			pointA.draw(graphics, 5, false);
			pointB.draw(graphics, 5, false);
			graphics.endFill();
			
			if ( vector.lengthSquared )
			{
				graphics.setLineStyle(2, distanceColor, qb2_debugDrawSettings.outlineAlpha);
				vector.draw(graphics, pointA, 0, 0);
			}
		}
	}
}