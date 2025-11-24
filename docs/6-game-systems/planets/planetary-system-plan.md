# Planetary system design - Solar System (plan)

Goal
- Create an extensible, data-driven planetary system for Unity.
- First target: stylized Solar System (Sun + 8 planets) represented as spheres with preserved relative proportions.
- System must be modular so new systems / hierarchical structures can be added later.

High-level constraints & choices
- Use Unity scene units as "scene units" (arbitrary, consistent). Provide a single scale factor to tune visual density.
- Represent bodies with simple spheres + materials initially; replaceable with models later.
- Data-driven: use ScriptableObject or JSON to define systems so authoring and runtime loading are simple.
- Keep simulation numerically cheap: use analytic circular/elliptical orbits and transform updates (no n-body physics).
- Expose time scale and toggle options for orbits/labels.

Stylized relative sizes and distances (example, tweakable via scale factors)
- Sizes (radius in scene units, stylized):
  - Sun: 5
  - Mercury: 0.2
  - Venus: 0.5
  - Earth: 0.5
  - Mars: 0.3
  - Jupiter: 1.5
  - Saturn: 1.2
  - Uranus: 0.8
  - Neptune: 0.8
- Distances (orbit radius from parent, scene units, stylized):
  - Mercury: 8
  - Venus: 11
  - Earth: 14
  - Mars: 18
  - Jupiter: 28
  - Saturn: 40
  - Uranus: 55
  - Neptune: 70
- Orbital periods (seconds, scene-time scaled; shorter value = faster orbit in demo)
  - Mercury: 8s, Venus: 12s, Earth: 16s, Mars: 24s, Jupiter: 48s, Saturn: 72s, Uranus: 128s, Neptune: 160s

Core architecture / components
- Data:
  - CelestialBodyData (ScriptableObject) - fields:
    - string name
    - float radius
    - float orbitRadius
    - float orbitalPeriod
    - float rotationPeriod
    - Color color / Material material
    - float axialTilt
    - bool hasRings
    - CelestialBodyData parent (optional)
- Runtime:
  - CelestialBody (MonoBehaviour)
    - Uses CelestialBodyData
    - Creates Sphere mesh / assigns material
    - Handles self-rotation (spin) and visual tilt
  - OrbitController (MonoBehaviour)
    - Updates local position using parent transform, orbitRadius, orbitalPeriod
    - Supports circular or elliptical (optional) orbit calculation
  - PlanetarySystemManager (MonoBehaviour)
    - Loads list of CelestialBodyData
    - Instantiates prefabs, sets parent-child relationships
    - Provides TimeScale, toggles (show orbit lines, labels)
- Utilities:
  - OrbitalVisualizer (draw orbit lines using LineRenderer)
  - Editor tooling to author ScriptableObject arrays and preview in editor
  - Serialization helpers (export/import JSON)

Extensibility notes
- Every body references a parent; hierarchical nesting supports moons, ring systems, binary stars.
- The data model is independent of rendering; renderer can be swapped (sphere -> mesh).
- Add gravitational/n-body later as optional module; keep current code decoupled.
- Provide public API: CreateBody(CelestialBodyData), RemoveBody(name), SetTimeScale(float), Pause()

Performance considerations
- Use simple per-frame transform updates (O(N)) where N = number of bodies.
- Precompute angular velocity w = 2π / orbitalPeriod to avoid repeated division.
- Use single shared sphere mesh / material variants to minimize draw calls.
- For large N, update orbits at lower frequency (e.g., every other frame) or use GPU instancing.

Minimal implementation steps (for first playable iteration)
1. Create CelestialBodyData ScriptableObjects for Sun + 8 planets (use stylized values above).
2. Create a Body prefab that contains CelestialBody, OrbitController, optional OrbitalVisualizer.
3. Implement PlanetarySystemManager to instantiate the solar system in Awake() or via editor.
4. Verify positions, scales, and correct parent-child linking in scene.
5. Add basic UI to control time scale and toggle orbit lines.

C# skeletons (short)

```csharp
// CelestialBodyData.cs
using UnityEngine;

[CreateAssetMenu(menuName = "Space/CelestialBodyData")]
public class CelestialBodyData : ScriptableObject {
    public string bodyName;
    public float radius;
    public float orbitRadius;
    public float orbitalPeriod; // seconds (scene-time)
    public float rotationPeriod; // seconds
    public Material material;
    public float axialTilt;
    public bool hasRings;
    public CelestialBodyData parent;
}
```

```csharp
// CelestialBody.cs
using UnityEngine;

[RequireComponent(typeof(MeshFilter), typeof(MeshRenderer))]
public class CelestialBody : MonoBehaviour {
    public CelestialBodyData data;
    float spinSpeed;

    void Start() {
        transform.localScale = Vector3.one * data.radius * 2f;
        GetComponent<MeshRenderer>().material = data.material;
        spinSpeed = 360f / Mathf.Max(0.0001f, data.rotationPeriod);
        transform.localRotation = Quaternion.Euler(data.axialTilt, 0f, 0f);
    }

    void Update() {
        transform.Rotate(Vector3.up, spinSpeed * Time.deltaTime * PlanetarySystemManager.Instance.TimeScale, Space.Self);
    }
}
```

```csharp
// OrbitController.cs
using UnityEngine;

public class OrbitController : MonoBehaviour {
    public CelestialBodyData data;
    Transform parentTransform;
    float angularSpeed;
    float angle; // current angle in radians

    void Start() {
        parentTransform = data.parent == null ? null : PlanetarySystemManager.Instance.GetTransformFor(data.parent.bodyName);
        angularSpeed = 2f * Mathf.PI / Mathf.Max(0.0001f, data.orbitalPeriod);
    }

    void Update() {
        if (parentTransform == null) return;
        angle += angularSpeed * Time.deltaTime * PlanetarySystemManager.Instance.TimeScale;
        Vector3 pos = new Vector3(Mathf.Cos(angle), 0f, Mathf.Sin(angle)) * data.orbitRadius;
        transform.position = parentTransform.position + pos;
    }
}
```

Next steps (implementation order)
- [x] Analyze requirements
- [ ] Create architecture & data model (ScriptableObject)
- [ ] Implement CelestialBody, OrbitController, PlanetarySystemManager
- [ ] Add prefabs and materials (sphere)
- [ ] Populate Solar System data assets
- [ ] Add visual polish: orbit lines, labels, toggles
- [ ] Performance checks and refactor for many bodies
- [ ] Add editor tooling for authoring and importing systems

Notes
- Values above are intentionally stylized for readability in-scene. Real astronomical scaling is not suitable for direct visualization.
- I will proceed to implement the ScriptableObject and core MonoBehaviours when you confirm to continue.

