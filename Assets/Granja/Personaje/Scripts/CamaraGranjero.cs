using UnityEngine;
using UnityEngine.InputSystem;

public class CamaraGranjero : MonoBehaviour
{
    [SerializeField] private Transform objetivo;
    [SerializeField] private LayerMask obstaculos = Physics.DefaultRaycastLayers;
    [SerializeField] private float distancia = 4.5f;
    [SerializeField] private float alturaObjetivo = 1.35f;
    [SerializeField] private float sensibilidad = 0.15f;
    [SerializeField] private float anguloHorizontal = 0;
    [SerializeField] private float anguloVertical = 18;

    private void LateUpdate()
    {
        if (!objetivo) return;
        Mouse raton = Mouse.current;
        if (raton != null && raton.rightButton.isPressed)
        {
            Vector2 movimiento = raton.delta.ReadValue();
            anguloHorizontal += movimiento.x * sensibilidad;
            anguloVertical = Mathf.Clamp(anguloVertical - movimiento.y * sensibilidad, -10, 65);
        }

        Vector3 centro = objetivo.position + Vector3.up * alturaObjetivo;
        Quaternion giro = Quaternion.Euler(anguloVertical, anguloHorizontal, 0);
        Vector3 direccion = giro * Vector3.back;
        float separacion = distancia;
        // Acercar la camara cuando hay una pared u otro obstaculo detras.
        if (Physics.SphereCast(centro, 0.18f, direccion, out RaycastHit choque,
            distancia, obstaculos, QueryTriggerInteraction.Ignore))
            separacion = Mathf.Max(0.25f, choque.distance - 0.1f);

        transform.position = centro + direccion * separacion;
        transform.LookAt(centro);
    }
}
