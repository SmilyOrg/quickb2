package 
{
	import As3Math.geo2d.*;
	import flash.display.*;
	import QuickB2.objects.tangibles.*;
	import QuickB2.stock.*;
	import surrender.srVectorGraphics2d;
	
	/** 
	 * Really simple example that pulls in the precompiled QuickB2.swc.
	 * 
	 * @author Doug Koellmer
	 */
	public class Main extends Sprite 
	{
		public function Main():void 
		{
			var world:qb2World = qb2Stock.newDebugWorld(new amVector2d(0, 10), new srVectorGraphics2d(this.graphics), stage);
			world.start();
			
			var circle:qb2CircleShape = qb2Stock.newCircleShape(new amPoint2d(100, 100), 50, 1);
			world.addObject(circle);
			
			var rectangle:qb2PolygonShape = qb2Stock.newRectShape(new amPoint2d(200, 200), 50, 25, 1);
			world.addObject(rectangle);
			
			var body:qb2Body = qb2Stock.newLineBody(new amPoint2d(300, 300), new amPoint2d(400, 400), 10, 1, qb2Stock.ENDS_ROUND);
			world.addObject(body);
			
			var walls:qb2StageWalls = new qb2StageWalls(stage);
			world.addObject(walls);
		}
	}
}