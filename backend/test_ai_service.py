import unittest
from unittest.mock import Mock, patch

from services import ai_service


class TestMedShurakshaAI(unittest.TestCase):
    @staticmethod
    def _provider_response(content):
        response = Mock()
        response.raise_for_status.return_value = None
        response.json.return_value = {"choices": [{"message": {"content": content}}]}
        return response

    def test_medicine_question_is_classified_then_answered(self):
        question = "Can I take paracetamol for fever?"
        with patch.object(ai_service, "GROQ_API_KEY", "test-key"), patch.object(
            ai_service.requests,
            "post",
            side_effect=[
                self._provider_response("IN_SCOPE"),
                self._provider_response("Paracetamol can help reduce fever."),
            ],
        ) as post:
            answer = ai_service.ask_ai(question)

        self.assertEqual(answer, "Paracetamol can help reduce fever.")
        self.assertEqual(post.call_count, 2)
        self.assertEqual(post.call_args_list[0].kwargs["json"]["messages"][-1]["content"], question)
        self.assertEqual(
            post.call_args_list[1].kwargs["json"]["messages"][0]["content"],
            ai_service.SYSTEM_PROMPT,
        )

    def test_programming_question_is_declined_before_answer_generation(self):
        question = "Give me Python code for palindrome"
        with patch.object(ai_service, "GROQ_API_KEY", "test-key"), patch.object(
            ai_service.requests,
            "post",
            return_value=self._provider_response("OUT_OF_SCOPE"),
        ) as post:
            answer = ai_service.ask_ai(question)

        self.assertEqual(answer, ai_service.OUT_OF_SCOPE_RESPONSE)
        post.assert_called_once()
        self.assertEqual(post.call_args.kwargs["json"]["messages"][-1]["content"], question)


if __name__ == "__main__":
    unittest.main()
