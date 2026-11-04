using UnityEngine;
using UnityEngine.InputSystem;

[RequireComponent(typeof(CharacterController))]
public class MovimientoGranjero : MonoBehaviour
{
    [SerializeField] private Transform camara;
    [SerializeField] private Animator animador;
    [SerializeField] private float velocidad = 1.8f;
    [SerializeField] private float velocidadCorrer = 5f;
    [SerializeField] private float velocidadGiro = 540f;
    [SerializeField] private float gravedad = -20f;

    private CharacterController controlador;
    private float velocidadVertical;
    private Vector3 posicionInicial;

    private void Awake()
    {
        controlador = GetComponent<CharacterController>();
        if (!camara && Camera.main) camara = Camera.main.transform;
        if (!animador) animador = GetComponentInChildren<Animator>();
        posicionInicial = transform.position;
    }

    private void Update()
    {
        Vector2 entrada = Vector2.zero;
        Keyboard teclado = Keyboard.current;
        bool saludando = false;
        if (animador)
        {
            saludando = animador.GetCurrentAnimatorStateInfo(0).IsTag("Saludo") ||
                (animador.IsInTransition(0) && animador.GetNextAnimatorStateInfo(0).IsTag("Saludo"));
            if (teclado != null && teclado.eKey.wasPressedThisFrame && !saludando)
            {
                animador.SetTrigger("Saludar");
                saludando = true;
            }
        }
        if (teclado != null && !saludando)
        {
            if (teclado.wKey.isPressed) entrada.y += 1;
            if (teclado.sKey.isPressed) entrada.y -= 1;
            if (teclado.dKey.isPressed) entrada.x += 1;
            if (teclado.aKey.isPressed) entrada.x -= 1;
        }
        // Normalizar evita que las diagonales sean mas rapidas.
        entrada = Vector2.ClampMagnitude(entrada, 1);
        Vector3 delante = camara ? camara.forward : Vector3.forward;
        Vector3 derecha = camara ? camara.right : Vector3.right;
        delante.y = 0;
        derecha.y = 0;
        Vector3 direccion = delante.normalized * entrada.y + derecha.normalized * entrada.x;
        bool correr = teclado != null && (teclado.leftShiftKey.isPressed || teclado.rightShiftKey.isPressed);
        float rapidez = correr ? velocidadCorrer : velocidad;

        if (direccion.sqrMagnitude > 0.001f)
        {
            Quaternion giro = Quaternion.LookRotation(direccion);
            transform.rotation = Quaternion.RotateTowards(transform.rotation, giro, velocidadGiro * Time.deltaTime);
        }

        if (controlador.isGrounded && velocidadVertical < 0) velocidadVertical = -2;
        velocidadVertical = Mathf.Max(velocidadVertical + gravedad * Time.deltaTime, -40);
        Vector3 anterior = transform.position;
        controlador.Move((direccion * rapidez + Vector3.up * velocidadVertical) * Time.deltaTime);

        // Al chocar y quedarse parado, tambien debe detenerse la animacion.
        Vector3 desplazamiento = transform.position - anterior;
        desplazamiento.y = 0;
        float movimiento = desplazamiento.magnitude / Mathf.Max(Time.deltaTime, 0.0001f);
        if (animador) animador.SetFloat("Velocidad", movimiento, 0.12f, Time.deltaTime);

        // Recuperar al jugador si alguna vez sale por debajo del escenario.
        if (transform.position.y < -10)
        {
            controlador.enabled = false;
            transform.position = posicionInicial;
            velocidadVertical = 0;
            controlador.enabled = true;
        }
    }
}
