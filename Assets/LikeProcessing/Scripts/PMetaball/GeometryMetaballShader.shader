﻿Shader "LikeProcessing/GeometryMetaballShader"
{
	Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", Color) = (0.1, 0.5, 0.7, 1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
 
        Pass
		{
			Cull Off

	        CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma geometry geom
           
            #include "UnityCG.cginc"
 
            struct appdata
            {
                float4 vertex : POSITION;
//                float3 normal : NORMAL;
//                float2 uv : TEXCOORD0;
                uint id : SV_VertexID;
            };
 
            struct v2f
            {
                float4 vertex : SV_POSITION;
//                float3 normal : NORMAL;
//                float2 uv : TEXCOORD0;
                float4 color : COLOR;
            };
 
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Color;

            float4 latticeWorldPosition;
            int detail;
            float deltaLen;
            float size;

            float4 _Cores[50];
            int _CoreCount;

            v2f vert (appdata v)
            {
                v2f o = (v2f)0;
                return o;
            }

            struct Point {
            	float3 loc;
            	float isoValue;
            	float3 normal;
            };

			struct Triangle {
				float3 vertices[3];
			};

            float culcIsoValue(float3 p, float4 core) {
	            //float result = new float[4];
				//Vector3 position = coreLocalPosition;
				//float sqrMagnitude = (p.loc - position).sqrMagnitude;
				float3 _core = float3(core.x, core.y, core.z);
				float3 v = p - _core;
				float sqrMagnitude = dot(v, v);
				float result = max(1.0 - (sqrMagnitude / 1.0), 0);
	//			Debug.Log (result[0]);
//				Vector3 normal = Vector3.zero;
//				if (result[0] != 0) {
//					normal = (2.0f * 1.0f / colliderRadiusSqrt) * (p.loc - position);	
//				}
//				result [1] = normal.x;
//				result [2] = normal.y;
//				result [3] = normal.z;
//            	return 1;
				return result;
            }

            bool lessThan (float3 left, float3 right)
			{
				if (left.x < right.x)
					return true;
				else if (left.x > right.x)
					return false;

				if (left.y < right.y)
					return true;
				else if (left.y > right.y)
					return false;

				if (left.z < right.z)
					return true;
				else if (left.z > right.z)
					return false;

				return false;
			}

            float3 LinearInterpolation (float isoLevel, Point p1, Point p2)
			{
				Point pp1 = p1;
				Point pp2 = p2;
				if (lessThan (p2.loc, p1.loc)) {
//					Point temp = (Point)0;
//					temp = p1;
					pp1 = p2;
					pp2 = p1;    
				}
				float3 intersection;
				if (abs (pp1.isoValue - pp2.isoValue) > 0.00001) {
					intersection.x = pp1.loc.x + (pp2.loc.x - pp1.loc.x) / (pp2.isoValue - pp1.isoValue) * (isoLevel - pp1.isoValue);
					intersection.y = pp1.loc.y + (pp2.loc.y - pp1.loc.y) / (pp2.isoValue - pp1.isoValue) * (isoLevel - pp1.isoValue);
					intersection.z = pp1.loc.z + (pp2.loc.z - pp1.loc.z) / (pp2.isoValue - pp1.isoValue) * (isoLevel - pp1.isoValue);
					//intersectionNormal = p1.normal + (p2.normal - p1.normal) / (p2.isoValue - p1.isoValue) * (isoLevel - p1.isoValue);
				} else {
					intersection = pp1.loc;
					//intersectionNormal = p1.normal;
				}
				return intersection;
			}

			void drawCenter(Point cubePoints[8], inout TriangleStream<v2f> OutputStream) {
				float3 center = (cubePoints[3].loc + cubePoints[5].loc) / 2.0;
				float hl = 0.02;
				float3 leftDown = center + float3(-hl, -hl, 0);
				float3 leftUp = center + float3(-hl, hl, 0);
				float3 rightUp = center + float3(hl, hl, 0);
				float3 rightDown = center + float3(hl, -hl, 0);
				v2f o = (v2f)0;
				o.color = float4(1, 100.0/255.0, 100.0/255.0, 1);
				o.vertex = UnityObjectToClipPos(leftDown);
				OutputStream.Append (o);
				o.vertex = UnityObjectToClipPos(leftUp);
				OutputStream.Append (o);
				o.vertex = UnityObjectToClipPos(rightDown);
				OutputStream.Append (o);
				o.vertex = UnityObjectToClipPos(rightUp);
				OutputStream.Append (o);
				OutputStream.RestartStrip();
			}

			void drawTriangle(float3 p1, float3 p2, float3 p3, float4 color, inout TriangleStream<v2f> OutputStream) {
				v2f o = (v2f)0;
				//o.color = float4(100.0/255.0, 150.0/255.0, 255.0/255.0, 1);
				o.color = color;
				o.vertex = UnityObjectToClipPos(p1);
				OutputStream.Append (o);
				o.vertex = UnityObjectToClipPos(p2);
				OutputStream.Append (o);
				o.vertex = UnityObjectToClipPos(p3);
				OutputStream.Append (o);
				OutputStream.RestartStrip();
			}

			void drawTetra(Point points[4], inout TriangleStream<v2f> OutputStream) {
				for (int i=0; i<4; i++) {
					float color = float4(100.0/255.0, 150.0/255.0, 255.0/255.0, 1);
					drawTriangle(points[0].loc, points[1].loc, points[2].loc, color, OutputStream);
					color = float4(120.0/255.0, 150.0/255.0, 255.0/255.0, 1);
					drawTriangle(points[0].loc, points[2].loc, points[3].loc, color, OutputStream);
					color = float4(140.0/255.0, 180.0/255.0, 255.0/255.0, 1);
					drawTriangle(points[0].loc, points[3].loc, points[1].loc, color, OutputStream);
					color = float4(160.0/255.0, 150.0/255.0, 255.0/255.0, 1);
					drawTriangle(points[1].loc, points[2].loc, points[3].loc, color, OutputStream);
				}
			}

			void drawLine(float3 p1, float p2, float width, inout TriangleStream<v2f> OutputStream) {
				float hl = width / 2.0;
				float3 leftDown = p1 + float3(0, -hl, 0);
				float3 leftUp = p1 + float3(0, hl, 0);
				float3 rightUp = p2 + float3(0, hl, 0);
				float3 rightDown = p2 + float3(0, -hl, 0);
				v2f o = (v2f)0;
				o.color = float4(1, 100.0/255.0, 100.0/255.0, 1);
				o.vertex = UnityObjectToClipPos(leftDown);
				OutputStream.Append (o);
				o.vertex = UnityObjectToClipPos(leftUp);
				OutputStream.Append (o);
				o.vertex = UnityObjectToClipPos(rightDown);
				OutputStream.Append (o);
				o.vertex = UnityObjectToClipPos(rightUp);
				OutputStream.Append (o);
				OutputStream.RestartStrip();
			}

			void drawTetraLines(Point points[4], inout TriangleStream<v2f> OutputStream) {
				float w = 0.05;
				drawLine(points[0].loc, points[1].loc, w, OutputStream);
				drawLine(points[0].loc, points[2].loc, w, OutputStream);
				drawLine(points[0].loc, points[3].loc, w, OutputStream);
				drawLine(points[1].loc, points[2].loc, w, OutputStream);
				drawLine(points[2].loc, points[3].loc, w, OutputStream);
				drawLine(points[3].loc, points[1].loc, w, OutputStream);
			}

			void drawCube(float3 p, float width, inout TriangleStream<v2f> OutputStream) {
				float hw = width / 2.0;
				float3 leftDownBack   = p + float3(-hw, -hw, -hw);
				float3 rightDownBack  = p + float3( hw, -hw, -hw);
				float3 rightDownFront = p + float3( hw, -hw,  hw);
				float3 leftDownFront  = p + float3(-hw, -hw,  hw);
				float3 leftUpBack     = p + float3(-hw,  hw, -hw);
				float3 rightUpBack    = p + float3( hw,  hw, -hw);
				float3 rightUpFront   = p + float3( hw,  hw,  hw);
				float3 leftUpFront    = p + float3(-hw,  hw,  hw);

				v2f o = (v2f)0;
				o.color = float4(100.0/255.0, 150.0/255.0, 255.0/255.0, 1);
				o.vertex = UnityObjectToClipPos(leftDownBack);
				OutputStream.Append (o);
				o.vertex = UnityObjectToClipPos(leftDownFront);
				OutputStream.Append (o);
				o.vertex = UnityObjectToClipPos(rightDownBack);
				OutputStream.Append (o);
				o.vertex = UnityObjectToClipPos(rightDownFront);
				OutputStream.Append (o);
				OutputStream.RestartStrip();

				o.vertex = UnityObjectToClipPos(leftUpBack);
				OutputStream.Append (o);
				o.vertex = UnityObjectToClipPos(leftUpFront);
				OutputStream.Append (o);
				o.vertex = UnityObjectToClipPos(rightUpBack);
				OutputStream.Append (o);
				o.vertex = UnityObjectToClipPos(rightUpFront);
				OutputStream.Append (o);
				OutputStream.RestartStrip();

				o.vertex = UnityObjectToClipPos(leftDownBack);
				OutputStream.Append (o);
				o.vertex = UnityObjectToClipPos(leftUpBack);
				OutputStream.Append (o);
				o.vertex = UnityObjectToClipPos(leftDownFront);
				OutputStream.Append (o);
				o.vertex = UnityObjectToClipPos(leftUpFront);
				OutputStream.Append (o);
				OutputStream.RestartStrip();

				o.vertex = UnityObjectToClipPos(rightDownBack);
				OutputStream.Append (o);
				o.vertex = UnityObjectToClipPos(rightUpBack);
				OutputStream.Append (o);
				o.vertex = UnityObjectToClipPos(rightDownFront);
				OutputStream.Append (o);
				o.vertex = UnityObjectToClipPos(rightUpFront);
				OutputStream.Append (o);
				OutputStream.RestartStrip();
			}

			void drawIsoValues(Point cubePoints[8], inout TriangleStream<v2f> OutputStream) {
				for (int i=0; i<8; i++) {
					Point p = cubePoints[i];
					drawCube(p.loc, p.isoValue * 1.0, OutputStream);
				}
			}

			void drawInterpolation(int nTriangle, Triangle triangles[2], inout TriangleStream<v2f>  OutputStream) {
				for (int i = 0; i < nTriangle; i++) {
					Triangle tri = triangles[i];
					for (int j = 0; j < 3; j++) {
						drawCube(tri.vertices[j], 0.06, OutputStream);
					}
				}
			}

			void drawInterpolationDebug(int tetraIndex, int nTriangle, Triangle triangles[2], inout TriangleStream<v2f>  OutputStream) {
				float count = 0;
//				if (tetraIndex != 0) {
//					return;
//				}
				float ft = (float) tetraIndex;
				for (int i = 0; i < nTriangle; i++) {
					Triangle tri = triangles[i];
					for (int j = 0; j < 3; j++) {
						float3 v = tri.vertices[j];
						float limit = 0.001;
						if (v.x < limit && v.y < limit && v.z < limit) {
							float fj = (float)j;
							float3 vv = v + float3(count* 0.03, ft * 0.1, 0); 
							drawCube(vv, 0.02, OutputStream);
							count += 1.0;
						}
					}
				}
			}

			void drawCore(inout TriangleStream<v2f>  OutputStream) {
				for (int j=0; j<_CoreCount; j++) {
        			float3 c = float3(_Cores[j].x, _Cores[j].y, _Cores[j].z);
        			drawCube(c, 0.02, OutputStream);
        		}
			}


 
            [maxvertexcount(128)]
            void geom(point v2f input[1], uint primitiveId : SV_PrimitiveID, inout TriangleStream<v2f> OutputStream)
            {
            	int edgeTable[256] = {
					0x0, 0x109, 0x203, 0x30a, 0x406, 0x50f, 0x605, 0x70c,
					0x80c, 0x905, 0xa0f, 0xb06, 0xc0a, 0xd03, 0xe09, 0xf00,
					0x190, 0x99, 0x393, 0x29a, 0x596, 0x49f, 0x795, 0x69c,
					0x99c, 0x895, 0xb9f, 0xa96, 0xd9a, 0xc93, 0xf99, 0xe90,
					0x230, 0x339, 0x33, 0x13a, 0x636, 0x73f, 0x435, 0x53c,
					0xa3c, 0xb35, 0x83f, 0x936, 0xe3a, 0xf33, 0xc39, 0xd30,
					0x3a0, 0x2a9, 0x1a3, 0xaa, 0x7a6, 0x6af, 0x5a5, 0x4ac,
					0xbac, 0xaa5, 0x9af, 0x8a6, 0xfaa, 0xea3, 0xda9, 0xca0,
					0x460, 0x569, 0x663, 0x76a, 0x66, 0x16f, 0x265, 0x36c,
					0xc6c, 0xd65, 0xe6f, 0xf66, 0x86a, 0x963, 0xa69, 0xb60,
					0x5f0, 0x4f9, 0x7f3, 0x6fa, 0x1f6, 0xff, 0x3f5, 0x2fc,
					0xdfc, 0xcf5, 0xfff, 0xef6, 0x9fa, 0x8f3, 0xbf9, 0xaf0,
					0x650, 0x759, 0x453, 0x55a, 0x256, 0x35f, 0x55, 0x15c,
					0xe5c, 0xf55, 0xc5f, 0xd56, 0xa5a, 0xb53, 0x859, 0x950,
					0x7c0, 0x6c9, 0x5c3, 0x4ca, 0x3c6, 0x2cf, 0x1c5, 0xcc,
					0xfcc, 0xec5, 0xdcf, 0xcc6, 0xbca, 0xac3, 0x9c9, 0x8c0,
					0x8c0, 0x9c9, 0xac3, 0xbca, 0xcc6, 0xdcf, 0xec5, 0xfcc,
					0xcc, 0x1c5, 0x2cf, 0x3c6, 0x4ca, 0x5c3, 0x6c9, 0x7c0,
					0x950, 0x859, 0xb53, 0xa5a, 0xd56, 0xc5f, 0xf55, 0xe5c,
					0x15c, 0x55, 0x35f, 0x256, 0x55a, 0x453, 0x759, 0x650,
					0xaf0, 0xbf9, 0x8f3, 0x9fa, 0xef6, 0xfff, 0xcf5, 0xdfc,
					0x2fc, 0x3f5, 0xff, 0x1f6, 0x6fa, 0x7f3, 0x4f9, 0x5f0,
					0xb60, 0xa69, 0x963, 0x86a, 0xf66, 0xe6f, 0xd65, 0xc6c,
					0x36c, 0x265, 0x16f, 0x66, 0x76a, 0x663, 0x569, 0x460,
					0xca0, 0xda9, 0xea3, 0xfaa, 0x8a6, 0x9af, 0xaa5, 0xbac,
					0x4ac, 0x5a5, 0x6af, 0x7a6, 0xaa, 0x1a3, 0x2a9, 0x3a0,
					0xd30, 0xc39, 0xf33, 0xe3a, 0x936, 0x83f, 0xb35, 0xa3c,
					0x53c, 0x435, 0x73f, 0x636, 0x13a, 0x33, 0x339, 0x230,
					0xe90, 0xf99, 0xc93, 0xd9a, 0xa96, 0xb9f, 0x895, 0x99c,
					0x69c, 0x795, 0x49f, 0x596, 0x29a, 0x393, 0x99, 0x190,
					0xf00, 0xe09, 0xd03, 0xc0a, 0xb06, 0xa0f, 0x905, 0x80c,
					0x70c, 0x605, 0x50f, 0x406, 0x30a, 0x203, 0x109, 0x0
				};

            	int cubeIndex = primitiveId & 0xffff;
            	int iz = cubeIndex / (detail * detail);
            	int iy = (cubeIndex % (detail * detail)) / detail;
            	int ix = (cubeIndex % (detail * detail)) % detail;

            	float fz = (float)iz;
            	float fy = (float)iy;
            	float fx = (float)ix;

            	float3 leftDown = float3(
            		-size + fx * deltaLen + latticeWorldPosition.x,
            		-size + fy * deltaLen + latticeWorldPosition.y,
            		-size + fz * deltaLen + latticeWorldPosition.z);

            	Point cubePoints[8] = {(Point)0, (Point)0, (Point)0, (Point)0, (Point)0, (Point)0, (Point)0, (Point)0};

            	cubePoints[0].loc = leftDown + float3(0, 0, deltaLen);	//left front down
            	cubePoints[1].loc = leftDown + float3(deltaLen, 0, deltaLen);	//right front down
            	cubePoints[2].loc = leftDown + float3(deltaLen, 0, 0); //right back down
            	cubePoints[3].loc = leftDown;	//left back down
            	cubePoints[4].loc = leftDown + float3(0, deltaLen, deltaLen);	//left front up
            	cubePoints[5].loc = leftDown + float3(deltaLen, deltaLen, deltaLen);	//right front up
            	cubePoints[6].loc = leftDown + float3(deltaLen, deltaLen, 0);	//right back up
            	cubePoints[7].loc = leftDown + float3(0, deltaLen, 0);	//left back up

//            	drawCenter(cubePoints, OutputStream);
//				drawCube(cubePoints[0].loc, 0.02, OutputStream);
//				drawCore(OutputStream);

            	for (int i=0; i<8; i++) {
            		Point p = cubePoints[i];
            		for (int j=0; j<_CoreCount; j++) {
            			p.isoValue += culcIsoValue(p.loc, _Cores[j]);
            		}
            		cubePoints[i] = p;
            	}

            	//drawIsoValues(cubePoints, OutputStream);

      			float isoLevel = 0.15;
            	int triIndex = 0;
				if (points[0].isoValue > isoLevel)
					triIndex |= 1;
				if (points [1].isoValue > isoLevel)
					triIndex |= 2;
				if (points [2].isoValue > isoLevel)
					triIndex |= 4;
				if (points [3].isoValue > isoLevel)
					triIndex |= 8;
				

				Triangle triangles[2] = {(Triangle)0, (Triangle)0};
				int nTriangle = 0;
				switch (triIndex) {
				   case 0x00:
				   case 0x0F:
				      break;
				   case 0x0E:
				   case 0x01:
				      triangles[0].vertices[0] = LinearInterpolation(isoLevel, points[0], points[1]);
				      triangles[0].vertices[1] = LinearInterpolation(isoLevel, points[0], points[2]);
				      triangles[0].vertices[2] = LinearInterpolation(isoLevel, points[0], points[3]);
				      nTriangle++;
				      break;
				   case 0x0D:
				   case 0x02:
				      triangles[0].vertices[0] = LinearInterpolation(isoLevel, points[1], points[0]);
				      triangles[0].vertices[1] = LinearInterpolation(isoLevel, points[1], points[3]);
				      triangles[0].vertices[2] = LinearInterpolation(isoLevel, points[1], points[2]);
				      nTriangle++;
				      break;
				   case 0x0C:
				   case 0x03:
				      triangles[0].vertices[0] = LinearInterpolation(isoLevel, points[0], points[3]);
				      triangles[0].vertices[1] = LinearInterpolation(isoLevel, points[0], points[2]);
				      triangles[0].vertices[2] = LinearInterpolation(isoLevel, points[1], points[3]);
				      nTriangle++;
				      triangles[1].vertices[0] = triangles[0].vertices[2];
				      triangles[1].vertices[1] = LinearInterpolation(isoLevel, points[1], points[2]);
				      triangles[1].vertices[2] = triangles[0].vertices[1];
				      nTriangle++;
				      break;
				   case 0x0B:
				   case 0x04:
				      triangles[0].vertices[0] = LinearInterpolation(isoLevel, points[2], points[0]);
				      triangles[0].vertices[1] = LinearInterpolation(isoLevel, points[2], points[1]);
				      triangles[0].vertices[2] = LinearInterpolation(isoLevel, points[2], points[3]);
				      nTriangle++;
				      break;
				   case 0x0A:
				   case 0x05:
				      triangles[0].vertices[0] = LinearInterpolation(isoLevel, points[0], points[1]);
				      triangles[0].vertices[1] = LinearInterpolation(isoLevel, points[2], points[3]);
				      triangles[0].vertices[2] = LinearInterpolation(isoLevel, points[0], points[3]);
				      nTriangle++;
				      triangles[1].vertices[0] = triangles[0].vertices[0];
				      triangles[1].vertices[1] = LinearInterpolation(isoLevel, points[1], points[2]);
				      triangles[1].vertices[2] = triangles[0].vertices[1];
				      nTriangle++;
				      break;
				   case 0x09:
				   case 0x06:
				      triangles[0].vertices[0] = LinearInterpolation(isoLevel, points[0], points[1]);
				      triangles[0].vertices[1] = LinearInterpolation(isoLevel, points[1], points[3]);
				      triangles[0].vertices[2] = LinearInterpolation(isoLevel, points[2], points[3]);
				      nTriangle++;
				      triangles[1].vertices[0] = triangles[0].vertices[0];
				      triangles[1].vertices[1] = LinearInterpolation(isoLevel, points[0], points[2]);
				      triangles[1].vertices[2] = triangles[0].vertices[2];
				      nTriangle++;
				      break;
				   case 0x07:
				   case 0x08:
				      triangles[0].vertices[0] = LinearInterpolation(isoLevel, points[3], points[0]);
				      triangles[0].vertices[1] = LinearInterpolation(isoLevel, points[3], points[2]);
				      triangles[0].vertices[2] = LinearInterpolation(isoLevel, points[3], points[1]);
				      nTriangle++;
				      break;
				}

//					drawInterpolation(nTriangle, triangles, OutputStream);
//					drawInterpolationDebug(tetraIndex, nTriangle, triangles, OutputStream);


			    v2f test = (v2f)0;
			    float c = triIndex / 10.0;
			    test.color = float4(c,c,c,c);
//				    test.color = float4(1,1,1,1	);
				for (int i=0; i<nTriangle; i++) {
            		Triangle tri = triangles[i];
            		test.vertex = UnityObjectToClipPos(tri.vertices[2]);
            		OutputStream.Append (test);
            		test.vertex = UnityObjectToClipPos(tri.vertices[1]);
            		OutputStream.Append (test);
            		test.vertex = UnityObjectToClipPos(tri.vertices[0]);
            		OutputStream.Append (test);
            		OutputStream.RestartStrip();
        		}
			}
           
            fixed4 frag (v2f i) : SV_Target
            {
//				float4 col = float4(1,1,1,1);
//				return col;
				return i.color;

			}

			ENDCG
        }
    }
}