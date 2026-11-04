using UnityEngine;

[DisallowMultipleComponent]
public class RotarAspasMolino : MonoBehaviour
{
    [SerializeField, Range(0, 20)] private float gradosPorSegundo = 6;

    private void Update()
    {
        // Seis grados por segundo equivalen a una vuelta por minuto.
        transform.Rotate(0, 0, gradosPorSegundo * Time.deltaTime, Space.Self);
    }
}
