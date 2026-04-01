import { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import api from "../../utils/api";
import { toast } from "react-toastify";

const NewCategory = ({ subjectId, moduleId, subjectTitle, onBack }) => {
  const [formData, setFormData] = useState({ title: "", desc: "", subjectId: subjectId || "", moduleId: moduleId || "" });
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  const handleChange = (e) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();

    if (!formData.title.trim()) {
      toast.error("Title is required");
      return;
    }

    if (!formData.moduleId || !formData.moduleId.trim()) {
      toast.error("Please select a module before adding a question");
      return;
    }

    setLoading(true);
    try {
      await api.post("/categories", formData);
      toast.success("Question added successfully");
      if (onBack) {
        onBack();
      } else {
        navigate("/categories");
      }
    } catch (error) {
      toast.error(error.response?.data?.message || "Something went wrong");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div>
      <button onClick={onBack ? onBack : () => navigate("/categories")} className="button button-block">
        Go Back
      </button>
      <div className="form-container">
        <form className="inner-container" onSubmit={handleSubmit}>
          <h2 className="form-title">Add New Question {subjectTitle ? `for ${subjectTitle}` : ""}</h2>
          <div className="form-group">
            <label>Question</label>
            <input
              className="form-control"
              type="text"
              name="title"
              value={formData.title}
              onChange={handleChange}
              placeholder="Type Important Question"
            />
          </div>

          <div className="form-group">
            <label>Answer</label>
            <textarea
              className="form-control"
              name="desc"
              value={formData.desc}
              onChange={handleChange}
              placeholder="Type Answer"></textarea>
            <h5>Important Note:</h5>
            <div className="card-desc">(Answer Only if You know Other wise just Add the question)</div>

          </div>

          <div className="form-group">
            <input
              className="button"
              type="submit"
              value={loading ? "Adding..." : "Add"}
              disabled={loading}
            />
          </div>
        </form>
      </div>
    </div>
  );
};

export default NewCategory;
