Shader "Instanced/CityLight" {
	Properties {
		
	}
	SubShader {

		Tags { "Queue"="Geometry" }
	
		Pass {

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			#pragma target 4.5

			#include "UnityCG.cginc"
			
			struct CityLight {
				float3 pointOnSphere;
				float height;
				float intensity;
				float randomT;
				int inRenderGroup;
			};

			StructuredBuffer<CityLight> CityLights;
			float sizeMin;
			float sizeMax;
			float3 dirToSun;
			float4 colourDim;
			float4 colourBright;
			float brightnessMultiplier;
			float turnOnTime;
			float turnOnTimeVariation;


			struct v2f
			{
				float4 pos : SV_POSITION;
				float show : TEXCOORD0;
				float4 colour : TEXCOORD1;
			};

			v2f vert (appdata_full v, uint instanceID : SV_InstanceID)
			{
				CityLight cityLight = CityLights[instanceID];

			

				// -1 = midnight; +1 = midday
				float sunDot = dot(cityLight.pointOnSphere, dirToSun);
				float lightAppear = turnOnTime + (cityLight.randomT-0.5) * turnOnTimeVariation;
				float scale = (lightAppear - sunDot) / 0.1;

				float size = lerp(sizeMin, sizeMax, cityLight.intensity) * 0.01 * saturate(scale);
				float3 vertexOffset = v.vertex.xyz * size;
				float3 worldCentre = cityLight.pointOnSphere * cityLight.height;
				float3 worldPosition = worldCentre + vertexOffset;

				float3 dirToCam = normalize(_WorldSpaceCameraPos.xyz - worldCentre);
				worldPosition += dirToCam*cityLight.intensity;

				v2f o;
				o.pos = mul(UNITY_MATRIX_VP, float4(worldPosition, 1.0f));
				o.show = scale; // when scale is negative this will tell the fragment shader not to render the light
				o.colour = lerp(colourDim, colourBright * brightnessMultiplier, cityLight.intensity);
				o.colour.a = cityLight.intensity + 2;
				return o;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				clip(i.show);
				return float4(i.colour.rgb, 10);
			}

			ENDCG
		}
	}
}