import unittest
from unittest.mock import patch

from services import ai_service


class TestMedShurakshaAI(unittest.TestCase):
    def test_medicine_and_general_questions_reach_ai_provider(self):
        answers = ["Paracetamol can help reduce fever.", "Paris is the capital of France."]
        provider_response = unittest.mock.Mock()
        provider_response.raise_for_status.return_value = None
        provider_response.json.side_effect = [
            {"choices": [{"message": {"content": answer}}]} for answer in answers
        ]

        with patch.object(ai_service, "GROQ_API_KEY", "test-key"), patch.object(
            ai_service.requests, "post", return_value=provider_response
        ) as post:
            actual_answers = [
                ai_service.ask_ai("Can I take paracetamol for fever?"),
                ai_service.ask_ai("What is the capital of France?"),
            ]

        self.assertEqual(actual_answers, answers)
        submitted_questions = [
            call.kwargs["json"]["messages"][-1]["content"]
            for call in post.call_args_list
        ]
        self.assertEqual(
            submitted_questions,
            ["Can I take paracetamol for fever?", "What is the capital of France?"],
        )


if __name__ == "__main__":
    unittest.main()
