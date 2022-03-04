#ifndef AN_COMMON
	#define AN_COMMON

	#include "UnityCG.cginc"
	#include "Lighting.cginc"
	#include "AutoLight.cginc"

	#define PI 3.14159265359
	#define INV_PI 0.31830988618f
	#define EPSILON 1e-4f

	sampler2D _MainTex;
	float4 _MainTex_ST;

	fixed4 _Color;
	fixed4 _HColor;
	fixed4 _SColor;

	float _RampThreshold;
	float _RampSmooth;

	#if EMISSION
		sampler2D _EmissionMap;
		float4 _EmissionMap_ST;
		half4 _EmissionColor;
	#endif

	#if SPECULAR
		float _SpecularRoughness;
		fixed4 _SpecularColor;
		sampler2D _SpecGlossMap;
		#if SPECULAR_STYLIZED || SPECULAR_CRISP
			half _SpecularToonSize;
			half _SpecularToonSmoothness;
		#endif
	#endif

	#if NORMAL_MAP
		sampler2D _NormalMapTex;
		float _NormalSmoothing;
	#endif

	#if RIM_LIGHTING
		fixed4 _RimColor;
		float _RimMin;
		float _RimMax;
	#endif

	#if GRADIENT
		float _GradPos;
		float _GradSize;
		fixed4 _GradTopColor;
		fixed4 _GradBottomColor;
	#endif

	#if WORLD_SPACE_UV
		float _TriBlendOffset;
		float _TriBlendExp;
	#endif

	#if PLANE_CLIPPING
		float3 _PlanePosition;
		float3 _PlaneNormal;
		fixed _ClipSectionEmmisive;
		fixed4 _ClipSectionColor;
	#endif

	#if OVERLAY_TEXTURE
		#if OVERLAY_PROJECTION
			float2 _ProjAngle;
			float4 _ProjScaleOffset;
		#endif
		sampler2D _OverlayTex;
		float4 _OverlayTex_ST;
		fixed4 _OverlayTint;
	#endif

	#if DISPLACEMENT
		sampler2D _DisplaceMap;
		float4 _DisplaceMap_TexelSize;
		float _DisplaceHeight;
	#endif

	struct appdata
	{
		float4 vertex : POSITION;
		float2 uv : TEXCOORD0;
		float3 normal : NORMAL;
#if VERTEX_COLOR
		fixed3 color : COLOR;
#endif
		#if DISPLACEMENT || NORMAL_MAP
			float3 tangent : TANGENT;
		#endif
	};

	struct v2f
	{
		float4 pos : SV_POSITION;
		float2 uv : TEXCOORD0;
		float3 worldPos : TEXCOORD4;
#if VERTEX_COLOR
		fixed3 color : COLOR2;
#endif
		#if SPECULAR || RIM_LIGHTING || OVERLAY_PROJECTION || PLANE_CLIPPING || ((DISPLACEMENT || NORMAL_MAP) && WORLD_SPACE_UV)
			float3 normal : NORMAL;
		#endif
		#if WORLD_SPACE_UV
			float3 triWeights : TEXCOORD3;
		#endif
		#if DISPLACEMENT || NORMAL_MAP
			float3x3 TBN : TEXCOORD5;
		#else
			fixed3 ambient : COLOR1;
			fixed3 ramp : COLOR0;
		#endif
		UNITY_FOG_COORDS(1)
		SHADOW_COORDS(2)
	};

	inline half3 SafeNormalize(half3 inVec)
	{
		half dp3 = max(0.001f, dot(inVec, inVec));
		return inVec * rsqrt(dp3);
	}

	#if SPECULAR
		inline half GGX(half NdotH, half roughness)
		{
			half a2 = roughness * roughness;
			half d = (NdotH * a2 - NdotH) * NdotH + 1.0f;
			return INV_PI * a2 / (d * d + EPSILON);
		}

		half CalculateSpecular(half3 lightDir, half3 viewDir, float3 normal, half specularMap)
		{
			half3 halfDir = SafeNormalize(lightDir + viewDir);
			half nh = saturate(dot(normal, halfDir));

			#if SPECULAR_STYLIZED || SPECULAR_CRISP
				half specSize = 1 - (_SpecularToonSize * specularMap);
				nh = nh * (1.0 / (1.0 - specSize)) - (specSize / (1.0 - specSize));
				#if defined(SPECULAR_CRISP)
					float specSmoothness = fwidth(nh);
				#else
					float specSmoothness = _SpecularToonSmoothness;
				#endif
				half spec = smoothstep(0, specSmoothness, nh);
			#else
				float specularRoughness = max(0.00001, _SpecularRoughness)* specularMap;
				half roughness = specularRoughness * specularRoughness;
				half spec = GGX(nh, saturate(roughness));
				spec *= PI * 0.05;
				#if UNITY_COLORSPACE_GAMMA
					spec = max(0, sqrt(max(1e-4h, spec)));
					half surfaceReduction = 1.0 - 0.28 * roughness * specularRoughness;
				#else
					half surfaceReduction = 1.0 / (roughness * roughness + 1.0);
				#endif
				spec *= surfaceReduction;
			#endif
			return max(0, spec);
		}
	#endif

	#if GRADIENT
		inline fixed4 GetGradientColor(float worldPosY)
		{
			float t = saturate((worldPosY - _GradPos + _GradSize / 2) / _GradSize);
			return lerp(_GradBottomColor, _GradTopColor, t);
		}
	#endif

	#if WORLD_SPACE_UV
		inline float3 GetTriPlanarWeights(float3 normal)
		{
			float3 triWeights = saturate(abs(normal) - _TriBlendOffset);
			triWeights = pow(triWeights, _TriBlendExp);
			return triWeights / (triWeights.x + triWeights.y + triWeights.z);
		}

		inline fixed4 TriplanarSample(sampler2D tex, float3 weights, float3 pos, float4 texST)
		{
			fixed4 colorXOZ = tex2D(tex, pos.xz * texST.xy + texST.zw) * weights.y;
			fixed4 colorXOY = tex2D(tex, pos.xy * texST.xy + texST.zw) * weights.z;
			fixed4 colorZOY = tex2D(tex, pos.zy * texST.xy + texST.zw) * weights.x;
			return colorXOZ + colorXOY + colorZOY;
		}

		inline fixed4 TriplanarSampleLod(sampler2D tex, float3 weights, float3 pos, float4 texST, float lod)
		{
			fixed4 colorXOZ = tex2Dlod(tex, float4(pos.xz * texST.xy + texST.zw, 0.0, lod)) * weights.y;
			fixed4 colorXOY = tex2Dlod(tex, float4(pos.xy * texST.xy + texST.zw, 0.0, lod)) * weights.z;
			fixed4 colorZOY = tex2Dlod(tex, float4(pos.zy * texST.xy + texST.zw, 0.0, lod)) * weights.x;
			return colorXOZ + colorXOY + colorZOY;
		}

		inline float3 GetTriplanarNormal(sampler2D normalMap, float3 weights, float3 wNormal, float3 wPos, float4 texST)
		{
			float2 uvZY = wPos.zy * texST.xy + texST.zw;
			float2 uvXZ = wPos.xz * texST.xy + texST.zw;
			float2 uvXY = wPos.xy * texST.xy + texST.zw;

			half3 tNormalZY = UnpackNormal(tex2D(normalMap, uvZY));
			half3 tNormalXZ = UnpackNormal(tex2D(normalMap, uvXZ));
			half3 tNormalXY = UnpackNormal(tex2D(normalMap, uvXY));

			half3 normalZY = half3(0, tNormalZY[1], tNormalZY[0]);
			half3 normalXZ = half3(tNormalXZ[0], 0, tNormalXZ[1]);
			half3 normalXY = half3(tNormalXY[0], tNormalXY[1], 0);

			return normalize(normalZY * weights.x +
							 normalXZ * weights.y +
							 normalXY * weights.z + 
							 wNormal);
		}
	#endif

	#if DISPLACEMENT
		inline float3 GetReconstructedNormal(sampler2D heightMap, float4 texelSize, float2 uv, float maxHeight, float4 texST)
		{
			float4 p;
			float3 n;
			p[0] = tex2Dlod(heightMap, float4(uv * texST.xy + texST.zw + float2(texelSize.x, 0.0), 0.0, 0.0)).r;
			p[1] = tex2Dlod(heightMap, float4(uv * texST.xy + texST.zw + float2(-texelSize.x, 0.0), 0.0, 0.0)).r;
			p[2] = tex2Dlod(heightMap, float4(uv * texST.xy + texST.zw + float2(0.0, texelSize.y), 0.0, 0.0)).r;
			p[3] = tex2Dlod(heightMap, float4(uv * texST.xy + texST.zw + float2(0.0, -texelSize.y), 0.0, 0.0)).r;
			p *= maxHeight;
			n.x = p[1] - p[0];
			n.y = p[3] - p[2];
			n.z = (2.0 / texelSize.z);

			return normalize(n);
		}

		inline float3 ReconstructNormalTriplanar(sampler2D heightMap, float4 texelSize, float3 weights, float3 wNormal, float3 wPos, float maxHeight, float4 texST)
		{
			half3 tNormalZY = GetReconstructedNormal(heightMap, texelSize, wPos.zy, maxHeight, texST);
			half3 tNormalXZ = GetReconstructedNormal(heightMap, texelSize, wPos.xz, maxHeight, texST);
			half3 tNormalXY = GetReconstructedNormal(heightMap, texelSize, wPos.xy, maxHeight, texST);

			half3 normalZY = half3(0, tNormalZY[1], tNormalZY[0]);
			half3 normalXZ = half3(tNormalXZ[0], 0, tNormalXZ[1]);
			half3 normalXY = half3(tNormalXY[0], tNormalXY[1], 0);

			return normalize(normalZY * weights.x +
							 normalXZ * weights.y +
							 normalXY * weights.z + 
							 wNormal);
		}
	#endif

	inline fixed3 GetLightingRamp(float3 normal)
	{
		fixed ndl = dot(normal, _WorldSpaceLightPos0) * 0.5 + 0.5;
		return smoothstep(_RampThreshold - _RampSmooth * 0.5, _RampThreshold + _RampSmooth * 0.5, ndl);
	}

	inline fixed3 GetLuminance(fixed3 ramp, float2 uv)
	{
		_SColor = lerp(_HColor, _SColor, _SColor.a);
		return lerp(_SColor.rgb, _HColor.rgb, ramp);
	}

	inline fixed4 CalculateShading(fixed3 diffuse, v2f i, fixed facing)
	{
		fixed3 ramp = 0.0, ambient = 0.0, emission = 0.0;
		float3 normal;
		#if SPECULAR || RIM_LIGHTING
			float3 viewDir = SafeNormalize(_WorldSpaceCameraPos.xyz - i.worldPos);
		#endif

		#if DISPLACEMENT || NORMAL_MAP
			#if WORLD_SPACE_UV
				#if DISPLACEMENT
					normal = ReconstructNormalTriplanar(_DisplaceMap, _DisplaceMap_TexelSize, i.triWeights, i.normal, i.worldPos, _DisplaceHeight, _MainTex_ST);
				#else
					normal = GetTriplanarNormal(_NormalMapTex, i.triWeights, i.normal, i.worldPos, _MainTex_ST);
					normal = lerp(normal, i.normal, _NormalSmoothing);
				#endif
			#else
				i.TBN = float3x3(normalize(i.TBN[0]), normalize(i.TBN[1]), normalize(i.TBN[2]));
				i.TBN = transpose(i.TBN);
				float3 tangentSpaceNormal;
				#if DISPLACEMENT
					tangentSpaceNormal = GetReconstructedNormal(_DisplaceMap, _DisplaceMap_TexelSize, i.uv, _DisplaceHeight, _MainTex_ST);
				#else
					tangentSpaceNormal = UnpackNormal(tex2D(_NormalMapTex, i.uv * _MainTex_ST.xy + _MainTex_ST.zw));
					tangentSpaceNormal = lerp(tangentSpaceNormal, float3(0,0,1), _NormalSmoothing);
				#endif
				normal = mul(i.TBN, tangentSpaceNormal);
			#endif
			ramp = GetLightingRamp(normal);
			ambient = ShadeSH9(half4(normal, 1));
		#else
			ramp = i.ramp;
			ambient = i.ambient;
			#if SPECULAR || RIM_LIGHTING || PLANE_CLIPPING
				normal = normalize(i.normal);
			#endif
		#endif

		#if PLANE_CLIPPING
			_PlaneNormal = normalize(_PlaneNormal);
			float blend = lerp(1, 0, step(0.5,facing)) * _ClipSectionColor.a;
			diffuse = lerp(diffuse, _ClipSectionColor, blend);
			diffuse *= step(0,_ClipSectionEmmisive);
			emission = lerp(emission, _ClipSectionColor, blend * _ClipSectionEmmisive);
			normal = lerp(_PlaneNormal, normal, step(0.5, facing));
			ramp = lerp(GetLightingRamp(normal), ramp, step(0.5,facing));
			ambient = lerp(ShadeSH9(half4(normal, 1)), ambient, step(0.5, facing));
		#endif

		fixed3 lum = GetLuminance(ramp, i.uv);
		fixed shadow = UNITY_SHADOW_ATTENUATION(i, i.worldPos);
		lum = lerp(_SColor, lum, shadow);
		fixed4 col = fixed4(ambient * diffuse, 1);
		col.rgb += diffuse * _LightColor0.rgb * lum;
		#if !GRADIENT
			col.rgb *= _Color;
		#endif
		
		#if RIM_LIGHTING
			half3 rimMask = half3(1.0, 1.0, 1.0);
			#if RIM_LIGHT_BASED
				rimMask = ramp * _LightColor0;
			#endif
			float ndv = 1.0 - max(0, dot(viewDir, normal));
			half rim = smoothstep(_RimMin, _RimMax, ndv);
			col.rgb += rimMask.rgb * rim * _RimColor.rgb;
		#endif

		#if SPECULAR
			#if WORLD_SPACE_UV
				float specularMap = TriplanarSample(_SpecGlossMap, i.triWeights, i.worldPos, _MainTex_ST);
			#else	
				float specularMap = tex2D(_SpecGlossMap, i.uv * _MainTex_ST.xy + _MainTex_ST.zw).r;
			#endif		
			half spec = CalculateSpecular(_WorldSpaceLightPos0, viewDir, normal, specularMap);
			half ndl = max(0.0, dot(normal, _WorldSpaceLightPos0));
			col.rgb += spec * specularMap* shadow* ndl * _LightColor0.rgb* _SpecularColor.rgb;
		#endif

		#if EMISSION
			emission += _EmissionColor;
			#if WORLD_SPACE_UV
				fixed3 emissionMap = TriplanarSample(_EmissionMap, i.triWeights, i.worldPos, _EmissionMap_ST).rgb;
			#else	
				fixed3 emissionMap = tex2D(_EmissionMap, i.uv * _EmissionMap_ST.xy + _EmissionMap_ST.zw).rgb;
			#endif
			emission *= emissionMap;
		#endif
		col.rgb += emission;
		return col;
	}

	v2f vert(appdata v)
	{
		v2f o;
		float3 normal = UnityObjectToWorldNormal(v.normal);
		o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
		#if WORLD_SPACE_UV
			o.triWeights = GetTriPlanarWeights(normal);
		#endif
#if VERTEX_COLOR
		o.color = v.color;
#endif
		o.uv = v.uv;
		#if DISPLACEMENT || NORMAL_MAP
			float3 worldTangent = mul((float3x3)unity_ObjectToWorld, v.tangent);
			float3 worldNormal = mul((float3x3)unity_ObjectToWorld, v.normal);
			float3 worldBiTangent = cross(worldTangent, worldNormal);
			o.TBN = float3x3(worldTangent, worldBiTangent, worldNormal);
			#if DISPLACEMENT
				#if WORLD_SPACE_UV
					float displace = TriplanarSampleLod(_DisplaceMap, o.triWeights, o.worldPos, _MainTex_ST, 0.0);
				#else
					float displace = tex2Dlod(_DisplaceMap, float4(v.uv * _MainTex_ST.xy + _MainTex_ST.zw, 0.0, 0.0)).r;
				#endif
				v.vertex.xyz = mul(unity_WorldToObject, float4(o.worldPos + worldNormal * displace * _DisplaceHeight,1.0));
			#endif
		#else
			o.ambient = ShadeSH9(half4(normal, 1));
			o.ramp = GetLightingRamp(normal);
		#endif
		#if SPECULAR || RIM_LIGHTING ||	OVERLAY_PROJECTION || PLANE_CLIPPING || ((DISPLACEMENT || NORMAL_MAP) && WORLD_SPACE_UV)
				o.normal = normal;
		#endif
		o.pos = UnityObjectToClipPos(v.vertex);
		UNITY_TRANSFER_FOG(o, o.pos);
		TRANSFER_SHADOW(o)
		return o;
	}

#if OVERLAY_TEXTURE && OVERLAY_PROJECTION
	float3 GetProjectionPlaneNormal()
	{
		_ProjAngle *= PI;
		return float3(cos(_ProjAngle.x) * cos(_ProjAngle.y), sin(_ProjAngle.y), sin(_ProjAngle.x) * cos(_ProjAngle.y));
	}

	float3x3 GetTransformationMatrix(float3 normal)
	{
		float3 t = normalize(float3(normal.z, 0, -normal.x));
		float3 b = cross(normal,t);
		return float3x3(t, b, normal);
	}
#endif

	fixed4 frag(v2f i, fixed facing : VFACE) : SV_Target
	{
		#if PLANE_CLIPPING
			clip(dot((_PlanePosition - i.worldPos), _PlaneNormal));
		#endif

		#if WORLD_SPACE_UV
			fixed4 diffuse = TriplanarSample(_MainTex, i.triWeights, i.worldPos, _MainTex_ST);
		#else
			fixed4 diffuse = tex2D(_MainTex, i.uv * _MainTex_ST.xy + _MainTex_ST.zw);
		#endif

#if VERTEX_COLOR
		diffuse.rgb *= i.color;
#endif

		fixed4 col = CalculateShading(diffuse, i, facing);

		#if OVERLAY_TEXTURE
			#if OVERLAY_PROJECTION
				float3 projPlaneNormal = GetProjectionPlaneNormal();
				float3 localPos = mul(unity_WorldToObject, i.worldPos - mul(unity_ObjectToWorld,float4(0, 0, 0, 1))).xyz;
				float2 uv = (mul(GetTransformationMatrix(projPlaneNormal),localPos )) / _ProjScaleOffset.xy + _ProjScaleOffset.zw + 0.5;
				fixed4 overlay = tex2D(_OverlayTex, uv) * step(0,dot(projPlaneNormal, i.normal));
			#elif WORLD_SPACE_UV
				fixed4 overlay = TriplanarSample(_OverlayTex, i.triWeights, i.worldPos, _OverlayTex_ST);
			#else
				fixed4 overlay = tex2D(_OverlayTex, i.uv * _OverlayTex_ST.xy + _OverlayTex_ST.zw);
			#endif
			col.rgb = lerp(saturate(col.rgb), overlay.rgb * _OverlayTint.rgb, overlay.a * _OverlayTint.a);
		#endif

		#if GRADIENT
			fixed4 gradCol = GetGradientColor(i.worldPos.y);
			col.rgb *= lerp(_Color, _Color * gradCol, gradCol.a);
		#endif
		UNITY_APPLY_FOG(i.fogCoord, col);
		return col;
	}
#endif